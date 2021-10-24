//
//  workout_mapApp.swift
//  workout-map
//
//  Created by Josh Lalonde on 2021-10-11.
//

import SwiftUI

@main
struct workout_mapApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                MapView()
            }.environmentObject(workoutManager)
        }
    }
}
