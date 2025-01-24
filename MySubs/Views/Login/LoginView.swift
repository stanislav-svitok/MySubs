//
//  LoginView.swift
//  MySubs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import SwiftUI
import NavigationFlow
import AuthenticationServices

struct LoginView: ActionSubmitView {
    enum Action: SubmitAction {
        case finish(Account)
    }

    @EnvironmentAction var submit: (Action) async throws -> Void
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession: WebAuthenticationSession
    
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Sign in required")
                .foregroundStyle(Color.textPrimary)
                .font(.title)
            
            Text("Application needs authorization to fetch your Youtube subscriptions. Please sign in using Google account.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.textSecondary)
                .font(.footnote)
                .padding(.bottom, 16)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(.regular)
                    .fixedSize()
                    .foregroundStyle(Color.blue)
            } else {
                Button(action: {
                    isLoading = true
                    do {
                        let urlWithCode = try await webAuthenticationSession.authenticate(
                            using: GoogleAPI.shared.accessURL,
                            callbackURLScheme: GoogleAPI.shared.callbackURLScheme
                        )
                        
                        try await GoogleAPI.shared.exchangeCodeForToken(url: urlWithCode)
                        let account = try await GoogleAPI.shared.getAccount()
                        try await submit(.finish(Account(picture: account.picture, name: account.name)))
                    } catch {
                        isLoading = false
                    }
                }, label: {
                    HStack(spacing: 10) {
                        Image(.googleLogo)
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("Sign in with Google")
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color.googleBackground)
                })
                .foregroundStyle(Color.textPrimary)
                .cornerRadius(22)
            }
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    LoginView()
}
