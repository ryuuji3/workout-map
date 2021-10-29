import Foundation
import HealthKit
import CoreLocation
import os
import Combine

private let logger = Logger(
    subsystem: "ryuuji3.workout-map.WorkoutManager",
    category: "WorkoutManager"
)

class WorkoutManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    
    var typesToRead: Set<HKObjectType> {
        [
            HKQuantityType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKSeriesType.workoutRoute()
        ]
    }
    
    static var workoutTypes: Set<WorkoutType> = [.cycling, .running, .walking]
    
    @Published var totalWorkoutsCount: Int = 0
    @Published var retrievedWorkouts: [Workout] = []
    
    var isLoading: Bool {
        retrievedWorkouts.count != totalWorkoutsCount
    }
    
    var totalDistance: CLLocationDistance {
        self.retrievedWorkouts.reduce(0) { totalDistance, workout in
            totalDistance + workout.totalDistance
        }
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    func getWorkouts(requestedTypes: Set<WorkoutType> = workoutTypes) {
        let unprocessedWorkouts = PassthroughSubject<HKWorkout, Never>()
        
        // Immediately load workouts and queue for processing
        self
            .requestAuthorization()
            .flatMap { isAuthorized -> AnyPublisher<[HKWorkout], Error> in
                guard isAuthorized else {
                    return Empty(completeImmediately: true)
                        .eraseToAnyPublisher()
                }
                
                return self
                    .workouts(requestedTypes: requestedTypes)
                    .collect() // Fetch all workouts so that we can batch fetching routes + locations
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { workouts in
                    unprocessedWorkouts.send(completion: .finished)
                },
                receiveValue: { [weak self] workouts in
                    for workout in workouts {
                        unprocessedWorkouts.send(workout)
                    }
                    // IMPORTANT: Update the total number of workouts so we can show loading spinner
                    self?.totalWorkoutsCount = workouts.count
                }
            )
            .store(in: &cancellables)
        
        // Process workouts
        unprocessedWorkouts
            .flatMap { self.details(workout: $0) }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] workout in
                    self?.retrievedWorkouts.append(workout)
                }
            )
            .store(in: &cancellables)
    }
    
    private func workouts(requestedTypes: Set<WorkoutType>) -> PassthroughSubject<HKWorkout, Error> {
        let subject = PassthroughSubject<HKWorkout, Error>()
        
        let workoutByType = NSCompoundPredicate(
            orPredicateWithSubpredicates: requestedTypes.map { HKQuery.predicateForWorkouts(with: HKWorkoutActivityType($0)) }
        )
        let query = HKSampleQuery(
            sampleType: HKSampleType.workoutType(),
            predicate: workoutByType,
            limit: Int(HKObjectQueryNoLimit),
            sortDescriptors: nil
        ) { workoutQuery, workoutsOrNil, errorOrNil in
            if let error = errorOrNil {
                logger.error("Error while querying workouts: \(error.localizedDescription)")
                
                return subject.send(completion: .finished)
            }
            
            guard let workouts = workoutsOrNil as? [HKWorkout] else {
                logger.warning("Workouts failed to be retrieved.")
                
                return subject.send(completion: .finished) // TODO: Maybe we should throw an error?
            }
            
            logger.log("Successfully queried \(workouts.count) workouts.")
            for workout in workouts {
                subject.send(workout)
            }
            subject.send(completion: .finished)
        }
        
        logger.info("Querying workouts...")
        self.healthStore.execute(query)
        
        return subject
    }
    
    private func requestAuthorization() -> AnyPublisher<Bool, Error> {
        Deferred {
            Future { handler in
                logger.info("Requesting authorization...")
                
                self.healthStore.requestAuthorization(toShare: nil, read: self.typesToRead) { success, error in
                    if let error = error {
                        logger.error("Authorization request failed: \(error.localizedDescription)")
                        handler(.failure(error))
                    } else {
                        logger.log("Authorization requested successfully.")
                        handler(.success(success))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func details(workout: HKWorkout) -> AnyPublisher<Workout, Error> {
        return self.routes(workout: workout)
            .flatMap { route in
                self.locations(route: route)
            }
            .replaceEmpty(with: [])
            .scan([]) { existingLocations, currentLocation in
                existingLocations + currentLocation
            }
            .last()
            .map { locations in
                return locations.sorted(by: { a, b in
                    a.timestamp <= b.timestamp
                })
            }
            .map { locations -> Workout in
                Workout(
                    id: workout.uuid,
                    startDate: workout.startDate,
                    endDate: workout.endDate,
                    type: WorkoutType(workout.workoutActivityType),
                    route: locations
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func routes(workout: HKWorkout) -> PassthroughSubject<HKWorkoutRoute, Error> {
        let subject = PassthroughSubject<HKWorkoutRoute, Error>()
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        // Needs to be anchored because data can change
        let query = HKAnchoredObjectQuery(
            type: HKSeriesType.workoutRoute(),
            predicate: predicate,
            anchor: nil,
            limit: Int(HKObjectQueryNoLimit)
        ) { (routeAnchoredQuery, workoutRoutesOrNil, deletedObjects, anchor, errorOrNil) in
            if let error = errorOrNil {
                logger.error("Error while querying specific workout route: \(error.localizedDescription)")
                
                return subject.send(completion: .failure(error))
            }
            
            guard let workoutRoutes = workoutRoutesOrNil as? [HKWorkoutRoute] else {
                logger.warning("Workout route failed to be retrieved.")
                
                return subject.send(completion: .finished)
            }
            
            logger.log("Successfully queried \(workoutRoutes.count) routes!")
            for workoutRoute in workoutRoutes {
                subject.send(workoutRoute)
            }
            
            subject.send(completion: .finished)
        }
        
        logger.info("Querying workout routes...")
        self.healthStore.execute(query)
        
        return subject
    }
    
    private func locations(route: HKWorkoutRoute) -> PassthroughSubject<[CLLocation], Error> {
        let subject = PassthroughSubject<[CLLocation], Error>()
        var results: [CLLocation] = []
        
        let query = HKWorkoutRouteQuery(route: route) { (routeQuery, locationsOrNil, done, errorOrNil) in
            if let error = errorOrNil {
                logger.error("Error while querying route: \(error.localizedDescription)")
                return subject.send(completion: .failure(error))
            }
            
            guard let locations = locationsOrNil else {
                logger.warning("Route failed to be retrieved.")
                
                subject.send([])
                return subject.send(completion: .finished)
            }
            
            results.append(contentsOf: locations)
            
            if done {
                logger.log("Finished querying \(locations.count) locations!")
                
                subject.send(results)
                subject.send(completion: .finished)
            }
        }
        
        logger.info("Querying route locations...")
        self.healthStore.execute(query)
        
        return subject
    }
}
