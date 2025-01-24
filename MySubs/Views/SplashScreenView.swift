//
//  SplashScreenView.swift
//  NavigationFlow
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import SwiftUI
import NavigationFlow

struct SplashScreenView: ActionSubmitView {    
    enum Action: SubmitAction {
        case presentLogin
        case showContent(Account)
    }

    @EnvironmentAction
    var submit: (Action) async throws -> Void
    
    var body: some View {
        VStack {
            Image(.logo)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Text("My Subs")
                .font(.largeTitle)
                .textCase(.uppercase)
                .foregroundStyle(.foreground)
            
            ProgressView()
                .progressViewStyle(.big)
                .foregroundStyle(Color.blue)
                .fixedSize()
            
        }
        .padding()
        .onAppear {
            Task {
                do {
                    let account = try await GoogleAPI.shared.getAccount()
                    try? await submit(.showContent(Account.init(picture: account.picture, name: account.name)))
                } catch {
                    try? await Task.sleep(for: .seconds(1))
                    try? await submit(.presentLogin)
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
