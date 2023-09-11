//
//  SuccessfulSIgnUpPage.swift
//  HexPtp
//
//  Created by Nick Aderhold on 7/24/23.
//

import SwiftUI

struct SuccessfulSignupPage: View {
    var userEmail: String // Add this property to store the user's email
    
    var body: some View {
        ZStack {
            Image("galaxywp")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                Text("Congratulations!")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                Text("You have successfully signed up!")
                    .font(.headline)

                NavigationLink(destination: MainUserPage(userEmail: userEmail)) {
                    Text("Continue to Main Page")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationBarTitle("")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}






