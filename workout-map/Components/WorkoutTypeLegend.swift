//
//  WorkoutTypeLegend.swift
//  workout-map
//
//  Created by Josh Lalonde on 2021-10-24.
//

import SwiftUI
import HealthKit

struct WorkoutTypeLegend: View {
    var loadedWorkoutTypes: [WorkoutType] = [.cycling, .running, .walking]
    
    var body: some View {
        VStack {
            ForEach(loadedWorkoutTypes) { workoutType in
                HStack {
                    Image(systemName: workoutType.logo)
                    Text(workoutType.name)
                }.foregroundColor(workoutType.color)
                .padding(.top, 1)
            }
        }
    }
}

struct WorkoutTypeLegend_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutTypeLegend()
    }
}
