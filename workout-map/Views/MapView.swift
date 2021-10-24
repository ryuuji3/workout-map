import SwiftUI
import MapKit
import HealthKit

struct MapView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    @State private var selectedWorkoutTypes: Set<HKWorkoutActivityType> = [.cycling, .walking]
    @State private var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 44.643324,
            longitude: -63.713239
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.1,
            longitudeDelta: 0.1
        )
    )
    
    var body: some View {
        let workouts = workoutManager.retrievedWorkouts
        let progress: Double = Double(workouts.count) / Double(workoutManager.totalWorkoutsCount)
        
        WorkoutMap(
            currentRegion: $currentRegion,
            workouts: workouts
        )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                workoutManager.getWorkouts(
                    requestedTypes: selectedWorkoutTypes
                )
            }
            .overlay(
                ProgressView("Loaded workouts: (\(workouts.count)/\(workoutManager.totalWorkoutsCount))", value: progress)
                    .progressViewStyle(.linear)
                    .padding(),
                alignment: .bottom
            )
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
            .environmentObject(WorkoutManager())
    }
}

extension HKWorkoutActivityType: Identifiable, Hashable {
    public var id: UInt {
        rawValue
    }

    var name: String {
        switch self {
        case .running:
            return "Run"
        case .cycling:
            return "Bike"
        case .walking:
            return "Walk"
        default:
            return ""
        }
    }
}
