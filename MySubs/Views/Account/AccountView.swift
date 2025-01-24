//
//  SettingsView.swift
//  MySubs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import SwiftUI
import NavigationFlow

struct AccountView: ActionSubmitView {
    enum Action: SubmitAction {
        case logout
    }
    
    let userName: String
    let iconPath: String

    @EnvironmentAction
    var submit: (Action) async throws -> Void
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: iconPath)) { result in
                if let image = result.image {
                    image
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                        .scaledToFit()
                } else {
                    Rectangle()
                        .foregroundStyle(Color.gray)
                        .aspectRatio(1.0, contentMode: .fit)
                }
            }

            Text(userName)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(.headline)
            
            Spacer()
            
            Button {
                try await submit(.logout)
            } label: {
                Text("Logout")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.bordered)
            .foregroundStyle(Color.red)
            .padding(.bottom, 16)
        }
        .padding()
    }
}

#Preview {
    AccountView(userName: "John Doe", iconPath: "")
}
