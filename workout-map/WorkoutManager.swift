import Foundation
import HealthKit
import CoreLocation
import os
import Combine

let logger = Logger(
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
    
    static var workoutTypes: Set<HKWorkoutActivityType> = [.cycling, .running, .walking]
    
    @Published var retrievedWorkouts: [Workout] = []
    
    private var cancellables: Set<AnyCancellable> = []
    
    func getWorkouts(requestedTypes: Set<HKWorkoutActivityType> = workoutTypes) {
        self
            .requestAuthorization()
            .flatMap { isAuthorized -> AnyPublisher<HKWorkout, Error> in
                guard isAuthorized else {
                    return Empty(completeImmediately: true)
                        .eraseToAnyPublisher()
                }
                
                return self
                    .workouts(requestedTypes: requestedTypes)
                    .eraseToAnyPublisher()
            }
            .flatMap { workout in
                workout.workoutWithDetails
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] workout in
                    self?.retrievedWorkouts.append(workout)
                }
            )
            .store(in: &cancellables)
    }
    
    private func workouts(requestedTypes: Set<HKWorkoutActivityType>) -> PassthroughSubject<HKWorkout, Error> {
        let subject = PassthroughSubject<HKWorkout, Error>()
        
        let workoutByType = NSCompoundPredicate(
            orPredicateWithSubpredicates: requestedTypes.map { HKQuery.predicateForWorkouts(with: $0) }
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
}

extension HKWorkout {
    public var workoutWithDetails: AnyPublisher<Workout, Error> {
        return routes
            .flatMap { route in
                route.locations
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
                    id: self.uuid,
                    startDate: self.startDate,
                    endDate: self.endDate,
                    type: self.workoutActivityType,
                    route: locations
                )
            }
            .eraseToAnyPublisher()
    }
    
    private var routes: PassthroughSubject<HKWorkoutRoute, Error> {
        let subject = PassthroughSubject<HKWorkoutRoute, Error>()
        let predicate = HKQuery.predicateForObjects(from: self)
        
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
        HKHealthStore().execute(query)
        
        return subject
    }
}

private extension HKWorkoutRoute {
    var locations: PassthroughSubject<[CLLocation], Error> {
        let subject = PassthroughSubject<[CLLocation], Error>()
        var results: [CLLocation] = []
        
        let query = HKWorkoutRouteQuery(route: self) { (routeQuery, locationsOrNil, done, errorOrNil) in
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
        HKHealthStore().execute(query)
        
        return subject
    }
}
