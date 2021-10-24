//
//  Map.swift
//  workout-map
//
//  Created by Josh Lalonde on 2021-10-20.
//

import SwiftUI
import MapKit

// Apparently you can't overlay with SwiftUI2 
struct WorkoutMap: UIViewRepresentable {
    @Binding var currentRegion: MKCoordinateRegion
    var workouts: [Workout]
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        
        map.setRegion(currentRegion, animated: true)
        
        return map
    }
    
    func updateUIView(_ map: MKMapView, context: Context) {
        map.delegate = context.coordinator
        
        // Clear all drawn lines before drawing
        map.removeOverlays(
            map.overlays.filter { overlay in
                overlay is MKMultiPolyline
            }
        )
        
        let workoutRoutes = MKMultiPolyline(
            workouts
                .map { workout in
                    MKPolyline(
                        coordinates: workout.route.map { location in
                            location.coordinate
                        },
                        count: workout.route.count
                    )
                }
        )
        map.addOverlay(workoutRoutes)
    }
    
    func makeCoordinator() -> WorkoutMapCoordinator {
        WorkoutMapCoordinator(self)
    }
    
    typealias UIViewType = MKMapView
}

class WorkoutMapCoordinator: NSObject, MKMapViewDelegate {
    var map: WorkoutMap
    
    init(_ control: WorkoutMap) {
        self.map = control
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let multiPolyline = overlay as? MKMultiPolyline {
            let renderer = MKMultiPolylineRenderer(multiPolyline: multiPolyline)
            
            renderer.strokeColor = .red
            renderer.lineWidth = 5.0
            renderer.alpha = 1.0
            
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
}

struct WorkoutMap_Previews: PreviewProvider {
    @State static var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 44.643324,
            longitude: -63.713239
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.1,
            longitudeDelta: 0.1
        )
    )
    
    static var previews: some View {
        WorkoutMap(
            currentRegion: $currentRegion,
            workouts: []
        )
    }
}
