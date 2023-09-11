//
//  structs.swift
//  HexPtp
//
//  Created by Nick Aderhold on 8/8/23.
//

import Foundation


struct Exercise: Identifiable {
    var id: String 
    var name: String?
    var repetitions: Int?
    var sets: Int?
    var videoLink: String?
    var order: Int?
    var weight: String? // Change the type to String
}



struct Workout: Identifiable {
    let id: String // Firestore document ID
    var date: Date
    var exercises: [Exercise]?
    var name: String // Add the name property here
    // Additional workout-related properties
    
    // You can also add an initializer if needed
}

struct WorkoutDay: Identifiable {
    let id: String
    var name: String // Name of the workout day
    var date: Date
    var workouts: [Workout]
    
    init(id: String, name: String, date: Date, workouts: [Workout] = []) {
        self.id = id
        self.name = name
        self.date = date
        self.workouts = workouts
    }
}

struct User: Identifiable, Hashable {
    let id: String
    var email: String
    var isPaid: Bool? // Updated field for "Paid"
    var remind: Bool? // Added field for "Remind"

    init(id: String, email: String, isPaid: Bool? = false, remind: Bool? = false) {
        self.id = id
        self.email = email
        self.isPaid = isPaid
        self.remind = remind
    }
}





// ThrowingWorkoutDay struct with an initializer
struct ThrowingWorkoutDay: Identifiable {
    let id: String // Firestore document ID
    var name: String
    var comment: String?
    var throwingWorkouts: [ThrowingWorkout] // Collection of ThrowingWorkouts
    
    // Initializer
    init(id: String, name: String, comment: String? = nil, throwingWorkouts: [ThrowingWorkout] = []) {
        self.id = id
        self.name = name
        self.comment = comment
        self.throwingWorkouts = throwingWorkouts
    }
}


// ThrowingWorkout struct
struct ThrowingWorkout: Identifiable {
    let id: String // Firestore document ID
    var name: String
    var throwingExercises: [ThrowingExercise]? // Collection of ThrowingExercises
    var order: Int? // Optional property for order
    var comment: String?

    
    // You can also add an initializer if needed
}

// ThrowingExercise struct
struct ThrowingExercise: Identifiable {
    let id: String // Firestore document ID
    var name: String
    var repetitions: Int?
    var sets: Int?
    var weight: String?
    var videoLink: String?
    var comments: String? // New property for comments
    var order: Int? // Optional property for order
    
    // You can also add an initializer if needed
}




