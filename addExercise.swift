//
//  addExercise.swift
//  HexPtp
//
//  Created by Nick Aderhold on 8/9/23.
//
import SwiftUI
import Firebase
import FirebaseFirestore

struct AddExercise: View {
    let db: Firestore
    let user: User
    @State var workout: Workout
    let workoutDay: WorkoutDay
    @State var showingExerciseDetailView = false
    @State private var selectedExercise: Exercise?

    // Add a state variable to hold the fetched exercises
    @State var exercises: [Exercise] = []

    var body: some View {
        NavigationView {
            VStack {
                Text("Add and Manage Exercises for \(workout.name)")
                    .font(.title)
                    .foregroundColor(.white)

                NavigationLink(destination: ExerciseDetailView(workout: $workout, workoutDay: workoutDay, exercises: $exercises, selectedExercise: $selectedExercise, db: db, user: user), isActive: $showingExerciseDetailView) {
                    EmptyView()
                }
                .opacity(0.0)

                Button(action: {
                    selectedExercise = nil // Reset selected exercise
                    showingExerciseDetailView = true
                }) {
                    Text("Add Exercise")
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                List {
                    ForEach(exercises.sorted(by: { $0.order ?? 0 < $1.order ?? 0 }), id: \.id) { exercise in
                        Button(action: {
                            selectedExercise = exercise
                            showingExerciseDetailView = true
                        }) {
                            HStack {
                                Text("\(exercise.order ?? 0):")
                                Text(exercise.name ?? "Exercise Name")
                            }
                        }
                    }
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
                // Fetch exercises for the current workout when the view appears
                fetchExercisesForWorkout()
            }
        }
    }

    // Function to fetch exercises for the current workout
    private func fetchExercisesForWorkout() {
        db.collection("Users")
            .document(user.id)
            .collection("WorkoutDays")
            .document(workoutDay.id)
            .collection("Workouts")
            .document(workout.id)
            .collection("Exercises")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching exercises: \(error)")
                    return
                }

                if let snapshot = snapshot {
                    self.exercises = snapshot.documents.compactMap { document in
                        guard let id = document.data()["id"] as? String,
                              let name = document.data()["name"] as? String,
                              let repetitions = document.data()["repetitions"] as? Int,
                              let sets = document.data()["sets"] as? Int,
                              let videoLink = document.data()["videoLink"] as? String,
                              let order = document.data()["order"] as? Int,
                              let weight = document.data()["weight"] as? String else {
                            return nil
                        }

                        return Exercise(id: id, name: name, repetitions: repetitions, sets: sets, videoLink: videoLink, order: order, weight: weight)
                    }
                }
            }
    }
}





struct ExerciseDetailView: View {
    @Binding var workout: Workout
    @State private var exerciseName: String = ""
    @State private var repetitions: String = ""
    @State private var sets: String = ""
    @State private var videoLink: String = ""
    @State private var order: String = ""
    @State private var weight: String = ""
    @State private var workoutDay: WorkoutDay
    @Binding var exercises: [Exercise]
    @Environment(\.presentationMode) var presentationMode

    let db: Firestore
    let user: User

    // Add a binding for the selected exercise
    @Binding var selectedExercise: Exercise?

    // Initialize selectedExercise with the currently selected exercise
    init(workout: Binding<Workout>, workoutDay: WorkoutDay, exercises: Binding<[Exercise]>, selectedExercise: Binding<Exercise?>, db: Firestore, user: User) {
        self._workout = workout
        self._workoutDay = State(initialValue: workoutDay)
        self._exercises = exercises
        self._selectedExercise = selectedExercise
        self.db = db
        self.user = user
    }

    var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Exercise Details")) {
                        TextField("Exercise Name", text: $exerciseName)
                        TextField("Repetitions", text: $repetitions)
                            .keyboardType(.numberPad)
                        TextField("Sets", text: $sets)
                            .keyboardType(.numberPad)
                        TextField("Video Link", text: $videoLink)
                        TextField("Order", text: $order)
                            .keyboardType(.numberPad)
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                    }

                    Section {
                        Button(action: saveExercise) {
                            Text("Save Exercise")
                        }
                        Button(action: deleteExercise) {
                            Text("Delete Exercise")
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationBarTitle("Edit Exercise")
            }
        .onAppear {
            if let exercise = selectedExercise {
                // Set the fields based on the selected exercise
                exerciseName = exercise.name ?? ""
                repetitions = "\(exercise.repetitions ?? 0)"
                sets = "\(exercise.sets ?? 0)"
                videoLink = exercise.videoLink ?? ""
                order = "\(exercise.order ?? 0)"
                weight = exercise.weight ?? ""
            }
        }
    }

    private func saveExercise() {
        guard !exerciseName.isEmpty else {
            return
        }

        if let existingExerciseIndex = exercises.firstIndex(where: { $0.id == selectedExercise?.id }) {
            // Update the existing exercise
            exercises[existingExerciseIndex].name = exerciseName
            exercises[existingExerciseIndex].repetitions = Int(repetitions) ?? 0
            exercises[existingExerciseIndex].sets = Int(sets) ?? 0
            exercises[existingExerciseIndex].videoLink = videoLink
            exercises[existingExerciseIndex].order = Int(order) ?? 0
            exercises[existingExerciseIndex].weight = weight

            // Update the exercise in Firestore
            updateExerciseInFirestore(exercise: exercises[existingExerciseIndex])
        } else {
            // Create a new Exercise instance with the entered details
            let newExercise = Exercise(
                id: UUID().uuidString,
                name: exerciseName,
                repetitions: Int(repetitions) ?? 0,
                sets: Int(sets) ?? 0,
                videoLink: videoLink,
                order: Int(order) ?? 0,
                weight: weight
            )

            // Append the new exercise to the local exercises array
            exercises.append(newExercise)

            // Save the exercise to Firestore
            saveExerciseToFirestore(exercise: newExercise)
        }

        // Reset the input fields
        exerciseName = ""
        repetitions = ""
        sets = ""
        videoLink = ""
        order = ""
        weight = ""

        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }

    private func updateExerciseInFirestore(exercise: Exercise) {
        // Get the Firestore reference to the exercise document
        let exerciseRef = db.collection("Users")
            .document(user.id)
            .collection("WorkoutDays")
            .document(workoutDay.id)
            .collection("Workouts")
            .document(workout.id)
            .collection("Exercises")
            .document(exercise.id)

        // Convert the Exercise object to a dictionary
        let exerciseData: [String: Any] = [
            "id": exercise.id,
            "name": exercise.name ?? "",
            "repetitions": exercise.repetitions ?? 0,
            "sets": exercise.sets ?? 0,
            "videoLink": exercise.videoLink ?? "",
            "order": exercise.order ?? 0,
            "weight": exercise.weight ?? ""
        ]

        // Update the exercise document in Firestore
        exerciseRef.setData(exerciseData, merge: true) { error in
            if let error = error {
                print("Error updating exercise in Firestore: \(error)")
            } else {
                print("Exercise updated successfully in Firestore.")
            }
        }
    }


    private func saveExerciseToFirestore(exercise: Exercise) {
        // Create a reference to the Firestore collection where you want to save the exercise
        let exercisesCollectionRef = db.collection("Users")
            .document(user.id)
            .collection("WorkoutDays")
            .document(workoutDay.id)
            .collection("Workouts")
            .document(workout.id)
            .collection("Exercises")

        // Convert the Exercise object to a dictionary
        let exerciseData: [String: Any] = [
            "id": exercise.id,
            "name": exercise.name ?? "",
            "repetitions": exercise.repetitions ?? 0,
            "sets": exercise.sets ?? 0,
            "videoLink": exercise.videoLink ?? "",
            "order": exercise.order ?? 0,
            "weight": exercise.weight ?? ""
        ]

        // Set the document data in Firestore
        exercisesCollectionRef.document(exercise.id).setData(exerciseData) { error in
            if let error = error {
                print("Error saving exercise to Firestore: \(error)")
            } else {
                print("Exercise added successfully to Firestore.")
            }
        }
    }
    
    private func deleteExercise() {
               guard let exerciseToDelete = selectedExercise else {
                   return
               }

               // Remove the exercise from the local exercises array
               exercises.removeAll { $0.id == exerciseToDelete.id }

               // Delete the exercise from Firestore
               deleteExerciseFromFirestore(exercise: exerciseToDelete)

               // Reset the input fields
               exerciseName = ""
               repetitions = ""
               sets = ""
               videoLink = ""
               order = ""
               weight = ""

               // Dismiss the sheet
               presentationMode.wrappedValue.dismiss()
           }

           // Add this function to delete the exercise from Firestore
           private func deleteExerciseFromFirestore(exercise: Exercise) {
               let exercisesCollectionRef = db.collection("Users")
                   .document(user.id)
                   .collection("WorkoutDays")
                   .document(workoutDay.id)
                   .collection("Workouts")
                   .document(workout.id)
                   .collection("Exercises")

               // Delete the exercise document from Firestore
               exercisesCollectionRef.document(exercise.id).delete { error in
                   if let error = error {
                       print("Error deleting exercise from Firestore: \(error)")
                   } else {
                       print("Exercise deleted successfully from Firestore.")
                   }
               }
           }
       }






















