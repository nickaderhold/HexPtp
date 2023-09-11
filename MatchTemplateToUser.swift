//
//  MatchTemplateToUser.swift
//  HexPtpApp
//
//  Created by Nick Aderhold on 9/8/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct AddTemplateToUser: View {
    let db = Firestore.firestore()
    
    @State private var sharedCollectionNames: [String] = []
    @State private var selectedSharedCollectionName: String?
    @State private var isShowingUsersView = false
    
    var body: some View {
        NavigationView {
            List(sharedCollectionNames, id: \.self) { collectionName in
                NavigationLink(destination: SharedCollectionUsersView(sharedCollectionName: collectionName)) {
                    Text(collectionName)
                }
            }
            .onAppear {
                fetchSharedCollectionNames()
            }
            .navigationBarTitle("Workout Templates")
        }
    }

    
    private func fetchSharedCollectionNames() {
        db.collection("SharedCollection").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching shared collection names: \(error)")
                return
            }
            
            if let snapshot = snapshot {
                self.sharedCollectionNames = snapshot.documents.compactMap { document in
                    return document.documentID
                }
            }
        }
    }
}

struct UserRow: View {
    let user: User
    let toggleMarkUserAsTemp: () -> Void
    let confirmClearWorkoutData: () -> Void

    var body: some View {
        HStack {
            Text(user.email) // Display user's email

            Button(action: {
                confirmClearWorkoutData()
            }) {
                Image(systemName: "arrow.backward.circle.fill") // Trash icon
                    .foregroundColor(.red)
            }

            Spacer()

            Button(action: {
                toggleMarkUserAsTemp()
            }) {
                if user.isTemp ?? false {
                    Image(systemName: "checkmark.circle.fill") // Green checkmark
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle") // Circle icon
                        .foregroundColor(.blue)
                }
            }
        }
    }
}



struct SharedCollectionUsersView: View {
    let db = Firestore.firestore()
    let sharedCollectionName: String

    @State private var users: [User] = []

    init(sharedCollectionName: String) {
        self.sharedCollectionName = sharedCollectionName
    }

    var body: some View {
        List(users, id: \.id) { user in
            HStack {
                Text(user.email) // Display user's email

                Button(action: {
                    // Delete button action
                    confirmClearWorkoutData(for: user)
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill") // Trash icon
                        .foregroundColor(.black)
                }
                .buttonStyle(PlainButtonStyle()) // Add PlainButtonStyle to prevent whole row from being tappable

                Spacer()

                Button(action: {
                    // Toggle button action
                    toggleMarkUserAsTemp(user: user)
                }) {
                    if user.isTemp ?? false {
                        Image(systemName: "checkmark.circle.fill") // Green checkmark
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle") // Circle icon
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(PlainButtonStyle()) // Add PlainButtonStyle to prevent whole row from being tappable
            }
        }
        .onAppear {
            fetchUsersFromFirestore()
        }
    }
    
    

    private func fetchUsersFromFirestore() {
        db.collection("Users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users from Firestore: \(error)")
                return
            }

            if let snapshot = snapshot {
                self.users = snapshot.documents.map { document in
                    let data = document.data()
                    let email = data["email"] as? String ?? ""
                    let isTemp = data["isTemp"] as? Bool ?? false // Read the isTemp field
                    return User(id: document.documentID, email: email, isTemp: isTemp)
                }
            }
        }
    }

    private func toggleMarkUserAsTemp(user: User) {
        // Toggle the isTemp field for the selected user
        let updatedIsTemp = !(user.isTemp ?? false)

        // Update the isTemp field in Firestore
        db.collection("Users").document(user.id).updateData(["isTemp": updatedIsTemp]) { error in
            if let error = error {
                print("Error updating isTemp field: \(error)")
            } else {
                print("isTemp field updated successfully.")
                
                // Update the local user list to reflect the change
                if let userIndex = self.users.firstIndex(where: { $0.id == user.id }) {
                    self.users[userIndex].isTemp = updatedIsTemp
                }
                
                // If the user is marked as temporary, copy the workout data
                if updatedIsTemp {
                    copyWorkoutDataToUser(user: user)
                }
            }
        }
    }

    private func copyWorkoutDataToUser(user: User) {
        // Fetch the entire WorkoutDays collection from the selected SharedCollection
        db.collection("SharedCollection")
            .document(sharedCollectionName)
            .collection("WorkoutDays")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching workout days: \(error)")
                    return
                }

                if let snapshot = snapshot {
                    let dispatchGroup = DispatchGroup()

                    for document in snapshot.documents {
                        dispatchGroup.enter()

                        let workoutDayId = document.documentID

                        // Copy the WorkoutDay data
                        db.collection("Users")
                            .document(user.id)
                            .collection("WorkoutDays")
                            .document(workoutDayId)
                            .setData(document.data()) { error in
                                if let error = error {
                                    print("Error copying WorkoutDay data: \(error)")
                                    dispatchGroup.leave()
                                    return
                                }

                                // Copy the workouts
                                db.collection("SharedCollection")
                                    .document(self.sharedCollectionName)
                                    .collection("WorkoutDays")
                                    .document(workoutDayId)
                                    .collection("Workouts")
                                    .getDocuments { snapshot, error in
                                        if let error = error {
                                            print("Error copying workouts: \(error)")
                                            dispatchGroup.leave()
                                            return
                                        }

                                        if let snapshot = snapshot {
                                            for workoutDocument in snapshot.documents {
                                                let workoutId = workoutDocument.documentID

                                                // Copy the workout data
                                                db.collection("Users")
                                                    .document(user.id)
                                                    .collection("WorkoutDays")
                                                    .document(workoutDayId)
                                                    .collection("Workouts")
                                                    .document(workoutId)
                                                    .setData(workoutDocument.data()) { error in
                                                        if let error = error {
                                                            print("Error copying workout data: \(error)")
                                                        }
                                                    }

                                                // Copy the exercises
                                                db.collection("SharedCollection")
                                                    .document(self.sharedCollectionName)
                                                    .collection("WorkoutDays")
                                                    .document(workoutDayId)
                                                    .collection("Workouts")
                                                    .document(workoutId)
                                                    .collection("Exercises")
                                                    .getDocuments { snapshot, error in
                                                        if let error = error {
                                                            print("Error copying exercises: \(error)")
                                                            return
                                                        }

                                                        if let snapshot = snapshot {
                                                            for exerciseDocument in snapshot.documents {
                                                                // Capture the exercise ID
                                                                let exerciseId = exerciseDocument.documentID

                                                                // Copy the exercise data
                                                                db.collection("Users")
                                                                    .document(user.id)
                                                                    .collection("WorkoutDays")
                                                                    .document(workoutDayId)
                                                                    .collection("Workouts")
                                                                    .document(workoutId)
                                                                    .collection("Exercises")
                                                                    .document(exerciseId)
                                                                    .setData(exerciseDocument.data()) { error in
                                                                        if let error = error {
                                                                            print("Error copying exercise data: \(error)")
                                                                        }
                                                                    }
                                                            }
                                                        }
                                                        dispatchGroup.leave()
                                                    }
                                            }
                                        }
                                    }
                            }
                    }

                    dispatchGroup.notify(queue: .main) {
                        print("Workout data copied to user successfully.")
                    }
                }
            }
    }
    
    
    private func confirmClearWorkoutData(for user: User) {
           let alert = UIAlertController(title: "Clear Workout Data", message: "Are you sure you want to clear workout data for \(user.email)?", preferredStyle: .alert)
           
           alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
           alert.addAction(UIAlertAction(title: "Clear", style: .destructive, handler: { _ in
               clearWorkoutData(for: user)
           }))
           
           // Present the alert
           UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
       }
       
    private func clearWorkoutData(for user: User) {
        // Define a Firestore batch to perform multiple delete operations
        let batch = db.batch()

        // Fetch the workout days associated with the user
        db.collection("Users")
            .document(user.id)
            .collection("WorkoutDays")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching workout days: \(error)")
                    return
                }

                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        let workoutDayId = document.documentID

                        // Delete the workout day document
                        let workoutDayRef = db.collection("Users")
                            .document(user.id)
                            .collection("WorkoutDays")
                            .document(workoutDayId)

                        batch.deleteDocument(workoutDayRef)
                    }

                    // Commit the batch to delete workout days
                    batch.commit { error in
                        if let error = error {
                            print("Error deleting workout days: \(error)")
                            return
                        }

                        print("Workout data cleared successfully for \(user.email).")
                    }
                }
            }
    }

}









struct SharedCollectionUsersView_Previews: PreviewProvider {
    static var previews: some View {
        SharedCollectionUsersView(sharedCollectionName: "YourSharedCollectionName")
    }
}








import SwiftUI

struct AddTemplateToUser_Previews: PreviewProvider {
    static var previews: some View {
        AddTemplateToUser()
    }
}


