import SwiftUI

@main
struct workout_mapApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                MapView()
            }
                .environmentObject(workoutManager)
                .environmentObject(locationManager)
        }
    }
}
