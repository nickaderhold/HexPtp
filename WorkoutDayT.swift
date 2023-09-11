//
//  WorkoutDayT.swift
//  HexPtpApp
//
//  Created by Nick Aderhold on 9/10/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct AddWorkoutDayT: View {
    let db: Firestore
    let sharedCollectionName: String
    @State private var newWorkoutDayName: String = ""
    @State private var workoutDays: [WorkoutDay] = []

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                Text("Add and Display Workout Days")
                    .font(.title)
                    .foregroundColor(.white) // Set font color to white

                TextField("Workout Day Name", text: $newWorkoutDayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: addWorkoutDay) {
                    Text("Add Day")
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                List {
                    ForEach(workoutDays.indices, id: \.self) { index in
                        NavigationLink(destination: AddWorkoutT(db: db, sharedCollectionName: sharedCollectionName, workoutDay: workoutDays[index])) {
                            HStack {
                                Text(workoutDays[index].name ?? "Default Name") // Provide a default value if name is nil
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                self.deleteWorkoutDay(at: index)
                            }) {
                                Text("Delete")
                                Image(systemName: "trash")
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .onAppear {
                fetchWorkoutDaysFromFirestore()
            }
            .background(
                Image("cool")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
            )
            .navigationBarTitle("Add and Display Workout Days", displayMode: .inline)
            .navigationBarItems(leading: backButton) // Use the custom back button
        }
        .navigationBarBackButtonHidden(true) // Hide the default back button
    }

    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.title)
                .foregroundColor(.white)
                .padding()
        }
    }

    private func addWorkoutDay() {
        guard !newWorkoutDayName.isEmpty else {
            return
        }

        let newWorkoutDay = WorkoutDay(id: UUID().uuidString, name: newWorkoutDayName, date: Date(), workouts: [])
        workoutDays.append(newWorkoutDay)

        db.collection("SharedCollection").document(sharedCollectionName).collection("WorkoutDays").document(newWorkoutDay.id).setData([
            "id": newWorkoutDay.id,
            "name": newWorkoutDay.name,
            "date": newWorkoutDay.date
        ]) { error in
            if let error = error {
                print("Error adding workout day: \(error)")
            } else {
                print("Workout day added successfully")
            }
        }

        newWorkoutDayName = ""
    }

    private func fetchWorkoutDaysFromFirestore() {
        db.collection("SharedCollection").document(sharedCollectionName).collection("WorkoutDays").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching workout days: \(error)")
                return
            }

            if let snapshot = snapshot {
                self.workoutDays = snapshot.documents.compactMap { document in
                    guard let id = document.data()["id"] as? String,
                          let name = document.data()["name"] as? String,
                          let dateTimestamp = document.data()["date"] as? Timestamp else {
                        return nil
                    }
                    let date = dateTimestamp.dateValue()
                    return WorkoutDay(id: id, name: name, date: date)
                }
            }
        }
    }

    private func deleteWorkoutDay(at index: Int) {
        let workoutDayToDelete = workoutDays[index]
        workoutDays.remove(at: index)

        db.collection("SharedCollection").document(sharedCollectionName).collection("WorkoutDays").document(workoutDayToDelete.id).delete { error in
            if let error = error {
                print("Error deleting workout day: \(error)")
            } else {
                print("Workout day deleted successfully")
            }
        }
    }
}

