//
//  WorkoutT.swift
//  HexPtpApp
//
//  Created by Nick Aderhold on 9/10/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct AddWorkoutT: View {
    let db: Firestore
    let sharedCollectionName: String
    let workoutDay: WorkoutDay
    @State private var workoutName: String = ""
    @State private var workouts: [Workout] = []

    @State private var deleteIndex: Int?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Add and Manage Workouts for \(workoutDay.name)")
                    .font(.title)
                    .foregroundColor(.white)

                TextField("Workout Name", text: $workoutName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: addWorkout) {
                    Text("Add Workout")
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                List {
                    ForEach(workouts.indices, id: \.self) { index in
                        NavigationLink(destination: AddExerciseT(db: db, sharedCollectionName: sharedCollectionName, workout: workouts[index], workoutDay: workoutDay)) {
                            Text(workouts[index].name)
                        }
                        .contextMenu {
                            Button(action: {
                                showDeleteConfirmation(at: index)
                            }) {
                                Text("Delete")
                                Image(systemName: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        // Handle swipe to delete
                        if let firstIndex = indexSet.first {
                            showDeleteConfirmation(at: firstIndex)
                        }
                    }
                }
                .actionSheet(isPresented: $showingDeleteConfirmation) {
                    ActionSheet(title: Text("Delete Workout"), message: Text("Are you sure you want to delete this workout?"), buttons: [
                        .destructive(Text("Delete")) {
                            confirmDeleteWorkout()
                        },
                        .cancel()
                    ])
                }

                Spacer()
            }
            .padding()
            .background(
                Image("cool")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
            )
            .onAppear {
                fetchWorkoutsFromFirestore()
            }
        }
    }

    private func addWorkout() {
        guard !workoutName.isEmpty else {
            return
        }

        // Create a new Workout instance with the entered details
        let newWorkout = Workout(id: UUID().uuidString, date: Date(), exercises: [], name: workoutName)
        workouts.append(newWorkout) // Append to `workouts`, not `exercises`

        // Save the new workout data to Firestore under the specified workout day in SharedCollection
        db.collection("SharedCollection").document(sharedCollectionName).collection("WorkoutDays").document(workoutDay.id).collection("Workouts").document(newWorkout.id).setData([
            "id": newWorkout.id,
            "date": newWorkout.date,
            "name": newWorkout.name,
            // Add other workout details to be saved in Firestore here
        ]) { error in
            if let error = error {
                print("Error adding workout: \(error)")
            } else {
                print("Workout added successfully")
            }
        }

        // Reset the input fields
        workoutName = ""
    }

    private func fetchWorkoutsFromFirestore() {
        db.collection("SharedCollection").document(sharedCollectionName).collection("WorkoutDays").document(workoutDay.id).collection("Workouts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching workouts: \(error)")
                return
            }

            if let snapshot = snapshot {
                self.workouts = snapshot.documents.compactMap { document in
                    guard let id = document.data()["id"] as? String,
                          let name = document.data()["name"] as? String,
                          let dateTimestamp = document.data()["date"] as? Timestamp else {
                        return nil
                    }
                    let date = dateTimestamp.dateValue()
                    return Workout(id: id, date: date, exercises: [], name: name)
                }
            }
        }
    }

    private func showDeleteConfirmation(at index: Int) {
        deleteIndex = index
        showingDeleteConfirmation = true
    }

    private func confirmDeleteWorkout() {
        if let deleteIndex = deleteIndex {
            let workoutToDelete = workouts[deleteIndex]
            workouts.remove(at: deleteIndex)
            showingDeleteConfirmation = false

            // Delete the workout from Firestore under the specified workout day in SharedCollection
            db.collection("SharedCollection")
                .document(sharedCollectionName)
                .collection("WorkoutDays")
                .document(workoutDay.id)
                .collection("Workouts")
                .document(workoutToDelete.id) // Specify the correct path to the document
                .delete { error in
                    if let error = error {
                        print("Error deleting workout from Firestore: \(error)")
                    } else {
                        print("Workout deleted from Firestore successfully")
                    }
                }
        }
    }
}

