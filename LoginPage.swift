//
//  LoginPage.swift
//  HexPtp
//
//  Created by Nick Aderhold on 7/24/23.
//

import SwiftUI
import Firebase

struct LoginPage: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var registrationError: String = ""

    @State private var isLoginSuccessful: Bool = false
    @State private var hasLoggedInBefore: Bool = UserDefaults.standard.bool(forKey: "HasLoggedInBefore")

    @State private var isAdmin = false
    @State private var isRegistering: Bool = false

    @AppStorage("RememberMe") var rememberMe: Bool = false
    @AppStorage("SavedEmail") var savedEmail: String = ""

    var body: some View {
        if isLoginSuccessful || (hasLoggedInBefore && !isAdmin) {
            if isAdmin {
                AdminProfile()
            } else {
                MainUserPage(userEmail: email)
            }
        } else {
            NavigationView {
                ZStack {
                    Image("galaxywp")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all) // Extend to edges of the screen

                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image("hexptp")
                            .resizable()
                            .frame(width: 150, height: 150)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .foregroundColor(.black)

                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .foregroundColor(.black)

                        Button(action: login) {
                            Text("Login")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }

                        Text(registrationError)
                            .foregroundColor(.red)
                            .padding(.top, 10)

                        NavigationLink(
                            destination: SignUpPage(),
                            isActive: $isRegistering) {
                                Text("Don't have an Account? Register")
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                        }
                        Button(action: resetPassword) {
                            Text("Forgot Password?")
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }


                        Spacer()
                    }
                }
                .onAppear {
                    if rememberMe && !savedEmail.isEmpty {
                        email = savedEmail
                    }

                    isLoginSuccessful = false
                    isAdmin = false

                    // Check if the user has logged in before
                    if hasLoggedInBefore {
                        print("User has logged in before")
                    } else {
                        print("User is signing in for the first time")
                    }
                }
                .padding(.horizontal, 20)
                .navigationBarHidden(true)
            }
            .navigationBarTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true) // Ensure the navigation bar is hidden
        }
    }
    
    private func resetPassword() {
        if email.isEmpty {
            registrationError = "Please enter your email to reset the password."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Password Reset Error: \(error.localizedDescription)")
                registrationError = "Password reset failed. Please check your email address."
            } else {
                registrationError = "Password reset email sent. Check your email for instructions."
            }
        }
    }


    private func login() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Login Error: \(error.localizedDescription)")
                registrationError = "Login failed. Please check your credentials."
            } else {
                if let uid = Auth.auth().currentUser?.uid, uid == "CXaU8TCah1OR7Gu3Eb6bn8UadC82" {
                    isAdmin = true
                } else {
                    isAdmin = false
                }

                isLoginSuccessful = true
                email = Auth.auth().currentUser?.email ?? ""
                
                if rememberMe {
                    savedEmail = email
                } else {
                    savedEmail = ""
                }

                hasLoggedInBefore = true
            }
        }
    }
}



struct LoginPage_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
    }
}




