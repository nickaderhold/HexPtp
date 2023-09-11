//
//  CreateWorkoutTemplate.swift
//  HexPtpApp
//
//  Created by Nick Aderhold on 9/8/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore


struct CreateWorkoutPlanView: View {
    // Initialize the Firestore database
    let db = Firestore.firestore()
    
    @State private var sharedCollectionName: String = ""
    @State private var sharedCollectionNames: [String] = []

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter Shared Collection Name", text: $sharedCollectionName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: addSharedCollection) {
                    Text("Add Shared Collection")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .disabled(sharedCollectionName.isEmpty)

                List {
                    ForEach(sharedCollectionNames, id: \.self) { collectionName in
                        NavigationLink(destination: AddWorkoutDayT(db: db, sharedCollectionName: collectionName)) {
                            Text(collectionName)
                        }
                        .contextMenu {
                            Button(action: {
                                deleteSharedCollection(collectionName)
                            }) {
                                Text("Delete")
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                .onAppear(perform: fetchSharedCollectionNames)
            }
        }
    }

    private func addSharedCollection() {
        guard !sharedCollectionName.isEmpty else {
            return
        }

        // Add the entered shared collection name to the list
        sharedCollectionNames.append(sharedCollectionName)

        // Create a Firestore document for the new shared collection name
        db.collection("SharedCollection").document(sharedCollectionName).setData([
            "name": sharedCollectionName
        ]) { error in
            if let error = error {
                print("Error adding shared collection: \(error)")
            } else {
                print("Shared collection added successfully to Firestore.")
            }
        }

        sharedCollectionName = ""
    }

    private func fetchSharedCollectionNames() {
        // Fetch shared collection names from Firestore
        db.collection("SharedCollection").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching shared collections: \(error)")
            } else {
                if let documents = querySnapshot?.documents {
                    // Extract shared collection names from Firestore documents
                    self.sharedCollectionNames = documents.map { $0.documentID }
                }
            }
        }
    }
    
    private func deleteSharedCollection(_ collectionName: String) {
        // Delete the Firestore document for the specified shared collection name
        db.collection("SharedCollection").document(collectionName).delete { error in
            if let error = error {
                print("Error deleting shared collection: \(error)")
            } else {
                // Remove the deleted collection name from the list
                if let index = sharedCollectionNames.firstIndex(of: collectionName) {
                    sharedCollectionNames.remove(at: index)
                }
                print("Shared collection deleted successfully.")
            }
        }
    }
}




















