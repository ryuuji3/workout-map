import SwiftUI
import MapKit
import HealthKit
import os

private let distanceFormatter = MKDistanceFormatter()

struct MapView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var locationManager: LocationManager
   
    @State private var selectedWorkoutTypes: Set<WorkoutType> = [.cycling, .walking, .running]
    @State private var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 37.3230,
            longitude: -122.0322
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.1,
            longitudeDelta: 0.1
        )
    )
    
    var body: some View {
        let workouts = workoutManager.retrievedWorkouts
        let progress: Double = Double(workouts.count) / Double(workoutManager.totalWorkoutsCount)
        let totalDistance: String = distanceFormatter.string(fromDistance: workoutManager.totalDistance)
        
        ZStack {
            WorkoutMap(
                currentRegion: $currentRegion,
                workouts: workouts
            )
                .edgesIgnoringSafeArea(.all)
                .onChange(of: locationManager.currentLocation) { location in
                    withAnimation {
                        if let newLocation = location {
                            self.currentRegion = MKCoordinateRegion(
                                center: newLocation.coordinate,
                                span: MKCoordinateSpan(
                                    latitudeDelta: 0.1,
                                    longitudeDelta: 0.1
                                )
                            )
                        }
                    }
                }
                .onAppear {
                    locationManager.getLocation()
                }
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
                
                VStack {
                    HStack {
                        Text("Total distance:")
                            .padding(.trailing, 10)
                        
                        LoadingView(isLoading: workoutManager.isLoading) {
                            Text(totalDistance)
                        }
                    }.padding()
                    
                    VStack {
                        ForEach(Array(selectedWorkoutTypes)) { workoutType in
                            let distanceForType = distanceFormatter.string(
                                fromDistance: workoutManager.totalDistanceByType(type: workoutType)
                            )
                            
                            HStack {
                                Group {
                                    Image(systemName: workoutType.logo)
                                    Text(workoutType.name)
                                        .padding(.trailing, 33)
                                }
                                
                                LoadingView(isLoading: workoutManager.isLoading) {
                                    Text(distanceForType)
                                }
                            }
                                .foregroundColor(workoutType.color)
                                .padding(.top, 1)
                        }
                    }
                }
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
            .environmentObject(WorkoutManager())
            .environmentObject(LocationManager())
    }
}
