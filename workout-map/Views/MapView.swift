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
        let workouts = workoutManager.retrievedWorkouts.filter {
            selectedWorkoutTypes.contains($0.type)
        }
        
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
                            workoutManager.getWorkouts() // start querying workouts AFTER location is determined
                        }
                    }
                }
                .onAppear {
                    locationManager.getLocation()
                }
            
            // TODO: Add animation 
            if workoutManager.progress < 1 {
                LoadingSpinner(
                    progress: workoutManager.progress
                )
            }
            
            WorkoutTypeFilter(
                selectedWorkoutTypes: $selectedWorkoutTypes
            )
            
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

// TODO: Refactor into a dumb component
struct WorkoutTypeFilter: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var selectedWorkoutTypes: Set<WorkoutType>
    
    var body: some View {
        let totalDistance: String = distanceFormatter.string(fromDistance: workoutManager.totalDistance)
        
        Legend {
            LabeledCalculation(
                isLoading: workoutManager.isLoading,
                label: {
                    Text("Total distance:")
                },
                result: {
                    Text(totalDistance)
                }
            )
            
            VStack {
                let workoutTypes: [WorkoutType] = [ .walking, .running, .cycling ]
                
                ForEach(workoutTypes, id: \.self) { workoutType in
                    let distanceForType = distanceFormatter.string(
                        fromDistance: workoutManager.totalDistanceByType(type: workoutType)
                    )
                    let isSelected = selectedWorkoutTypes.contains(workoutType)
                    
                    ZStack {
                        HStack {
                            LabeledCalculation(
                                isLoading: workoutManager.isLoading,
                                label: {
                                    Group {
                                        if let logo = workoutType.logo {
                                            Image(systemName: logo)
                                        }
                                        Text(workoutType.name)
                                            .padding(.trailing, 33)
                                    }
                                },
                                result: {
                                    Text(distanceForType)
                                }
                            )
                        }
                        .foregroundColor(isSelected ? Color.white : workoutType.color)
                        .background(isSelected ? workoutType.color : Color.black.opacity(0.4))
                        .padding(.bottom, 1)
                        .onTapGesture {
                            if isSelected {
                                self.selectedWorkoutTypes.remove(workoutType)
                            } else {
                                self.selectedWorkoutTypes.insert(workoutType)
                            }
                        }
                    }
                }
            }
        }
    }
}
