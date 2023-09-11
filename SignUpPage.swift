//
//  SignUpPage.swift
//  HexPtp
//
//  Created by Nick Aderhold on 7/24/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore


struct SignUpPage: View {
    @State private var email: String = ""
    @State private var confirmEmail: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var signUpError: String = ""
    @State private var isSignUpSuccessful = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("galaxywp")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer()

                    Text("Sign Up")
                        .font(.largeTitle)
                        .foregroundColor(.blue)

                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .frame(width: UIScreen.main.bounds.width - 40)
                        .foregroundColor(.black)

                    TextField("Confirm Email", text: $confirmEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .frame(width: UIScreen.main.bounds.width - 40)
                        .foregroundColor(.black)

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .frame(width: UIScreen.main.bounds.width - 40)
                        .foregroundColor(.black)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .frame(width: UIScreen.main.bounds.width - 40)
                        .foregroundColor(.black)

                    Button(action: signUp) {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }

                    Text(signUpError)
                        .foregroundColor(.red)
                        .padding(.top, 10)

                    Spacer()

                    NavigationLink(
                        destination: SuccessfulSignupPage(userEmail: email),
                        isActive: $isSignUpSuccessful,
                        label: { EmptyView() }
                    )
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitle("Sign Up")
            .navigationBarHidden(true)
        }
    }

    private func signUp() {
        guard email == confirmEmail else {
            signUpError = "Emails do not match"
            return
        }

        guard password == confirmPassword else {
            signUpError = "Passwords do not match"
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Sign-Up Error: \(error.localizedDescription)")
                signUpError = "Error: \(error.localizedDescription)"
            } else {
                // Sign-up successful, add user document to Firestore
                addUserDataToFirestore()
                isSignUpSuccessful = true
            }
        }
    }

    private func addUserDataToFirestore() {
        guard let user = Auth.auth().currentUser else {
            return
        }

        let db = Firestore.firestore()

        let userDocument = [
            "email": user.email ?? "",
            
            // Add other user properties as needed
        ]

        // Use the user's UID as the document ID
        db.collection("Users").document(user.uid).setData(userDocument) { error in
            if let error = error {
                print("Error adding user document to Firestore: \(error.localizedDescription)")
            } else {
                print("User document added to Firestore successfully!")
            }
        }
    }

}


    


struct SignUpPage_Previews: PreviewProvider {
    static var previews: some View {
        SignUpPage()
    }
}
