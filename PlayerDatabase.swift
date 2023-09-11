import SwiftUI
import Firebase
import FirebaseFirestore

struct PlayerDatabase: View {
    @State private var users: [User] = []
    @State private var selectedUser: User? = nil
    @State private var currentUserID: String? = nil // Add this state variable to hold the current user ID

    private var db = Firestore.firestore()

    @State private var isManageUserClicked = false // Add a boolean flag for "Manage User" click

    var body: some View {
        NavigationView {
            ZStack {
                Image("graf") // Background image
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    VStack {
                        Rectangle()
                            .frame(height: 40) // Adjust the height of the white rectangle
                            .foregroundColor(.white)
                            .opacity(0.7) // Adjust opacity as needed
                            .overlay(
                                Text("Users")
                                    .font(.title)
                                    .foregroundColor(.black)
                            )
                    }
                    .padding(.top) // Move the Users text to the top

                    List(users) { user in
                        Button(action: {
                            selectedUser = selectedUser == user ? nil : user
                            currentUserID = selectedUser?.id // Store the current user ID
                            isManageUserClicked = true // Set the flag to show ManageUserView
                        }) {
                            Text(user.email)
                                .font(.headline)
                                .foregroundColor(selectedUser == user ? .green : .blue)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                    .onAppear {
                        fetchUsersFromFirestore()
                    }

                    if let selectedUser = selectedUser {
                        Button(action: {
                            isManageUserClicked = true // Set the flag to show ManageUserView
                        }) {
                            Text("Manage \(selectedUser.email)")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .padding()
                    }

                    Spacer() // Push content to the top
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationViewStyle(StackNavigationViewStyle()) // Use StackNavigationViewStyle
            .fullScreenCover(isPresented: $isManageUserClicked) {
                // Present the ManageUserView
                if let selectedUser = selectedUser {
                    ManageUserView(user: selectedUser, db: db, users: $users)
                }
            }
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
                    User(id: document.documentID, email: document.data()["email"] as? String ?? "")
                }
            }
        }
    }
}




struct PlayerDatabase_Previews: PreviewProvider {
    static var previews: some View {
        PlayerDatabase()
    }
}
























