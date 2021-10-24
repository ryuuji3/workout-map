import SwiftUI
import MapKit
import HealthKit

struct MapView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
   
    @State private var selectedWorkoutTypes: Set<WorkoutType> = [.cycling, .walking, .running]
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
        
        ZStack {
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
            
            // TODO: Add animation 
            if progress < 1 {
                LoadingSpinner(
                    progress: progress
                )
            }
            
            VStack {
                Spacer()
                WorkoutTypeLegend(loadedWorkoutTypes: Array(selectedWorkoutTypes))
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
            .environmentObject(WorkoutManager())
    }
}
