//
//  WorkoutType.swift
//  workout-map
//
//  Created by Josh Lalonde on 2021-10-24.
//

import Foundation
import HealthKit
import SwiftUI


public enum WorkoutType: Identifiable, Hashable, CaseIterable {
    case walking
    case running
    case cycling
    case other // other workout types that we don't really care about
    
    public var id: Self {
        self
    }
    
    var name: String {
        switch self {
            case .running:
                return "Running"
            case .cycling:
                return "Biking"
            case .walking:
                return "Walking"
            default:
                return "Other"
        }
    }
    
    var logo: String {
        switch self {
            case .running:
                return "figure.walk" // TODO: Find a better one
            case .walking:
                return "figure.walk"
            case .cycling:
                return "bicycle"
            default: return "" // no symbol
        }
    }
    
    var color: Color {
        switch self {
            case .running:
                return .red
            case .walking:
                return .blue
            case .cycling:
                return .green
            default: return .black
        }
    }
    
    // compatibility with HKWorkoutActivityType
    init(_ type: HKWorkoutActivityType) {
        switch type {
            case .running:
                self = .running
                break
            case .cycling:
                self = .cycling
                break
            case .walking:
                self = .walking
                break
            default:
                self = .other
                break
        }
    }
}

extension HKWorkoutActivityType {
    init(_ type: WorkoutType) {
        switch type {
            case .running:
                self = .running
                break
            case .cycling:
                self = .cycling
                break
            case .walking:
                self = .walking
                break
            default:
                self = .other
                break
        }
    }
}
