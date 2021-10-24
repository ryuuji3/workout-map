//
//  Workout.swift
//  workout-map
//
//  Created by Josh Lalonde on 2021-10-11.
//

import Foundation
import HealthKit
import CoreLocation

public class Workout: Identifiable {
    public var id: UUID
    public var startDate: Date
    public var endDate: Date
    public var type: WorkoutType
    public var route: [CLLocation]
    
    init(
        id: UUID,
        startDate: Date,
        endDate: Date,
        type: WorkoutType,
        route: [CLLocation]
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
        self.route = route
    }
}
