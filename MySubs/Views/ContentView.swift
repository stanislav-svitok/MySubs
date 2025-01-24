//
//  ContentView.swift
//  MySubs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import SwiftUI
import NavigationFlow

struct Account: Equatable, Hashable {
    let picture: String
    let name: String
}

struct ContentView: View {
    enum Destination {
        case splashScreen
        case login
        case main(Account)//example of holding data without explicit variable storage in view
        case subscriptionList
        case account(Account)
        case subscriptionDetail(title: String, id: String)
    }

    var body: some View {
        UINavigationFlow(root: Destination.splashScreen) { destination in
            switch destination {
            case .splashScreen:
                SplashScreenView()
                    .watermarked(with: "*")//still able to use onSubmit() even after using Modifier on SplashScreenView()
                    .onSubmit { action in
                        switch action {
                        case .presentLogin:
                            return .sheet(.login)
                            
                        case .showContent(let account):
                            return .pushReplace(.main(account), backButtonEnabled: false)
                        }
                    }
                
            case .login:
                LoginView()
                    .onSubmit { action in
                        switch action {
                        case .finish(let account):
                            return .dismissPresented.then(.pushReplace(.main(account), backButtonEnabled: false))
                        }
                    }
                
            case .main(let account):
                TabFlow(.subscriptionList, .account(account))
                
            case .subscriptionList:
                SubscriptionListView()
                    .onSubmit { action in
                        switch action {
                        case .refreshContent(let itemsBinding, let nextPageBinding):
                            let response = try await GoogleAPI.shared.getSubscriptions(page: nextPageBinding.wrappedValue)
                            if nextPageBinding.wrappedValue == nil {
                                itemsBinding.wrappedValue = response.items.map { $0.subscriptionItem }
                            } else {
                                itemsBinding.wrappedValue = itemsBinding.wrappedValue + response.items.map { $0.subscriptionItem }
                            }
                            nextPageBinding.wrappedValue = response.nextPageToken
                            return .keep
                            
                        case .select(let item):
                            return .push(.subscriptionDetail(title: item.title, id: item.id))
                        }
                    }
                
            case .subscriptionDetail(_, let id):
                SubscriptionDetailView()
                    .onSubmit { action in
                        switch action {
                        case .refreshContent(let itemBinding):
                            let response = try await GoogleAPI.shared.get(channel: id)
                            itemBinding.wrappedValue = response.detailItem
                            return .keep
                        }
                    }
                
            case .account(let account):
                AccountView(userName: account.name, iconPath: account.picture)
                    .onSubmit { action in
                        switch action {
                        case .logout:
                            GoogleAPI.shared.logout()
                            return .popToRoot
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}

extension GoogleAPI.SubscriptionItem {
    var subscriptionItem: SubscriptionListView.Item {
        SubscriptionListView.Item(id: snippet.resourceId?.channelId ?? id, title: snippet.title, subtitle: snippet.description, imagePath: snippet.thumbnails["default"]?.url)
    }
    
    var detailItem: SubscriptionDetailView.Item {
        let viewCount = statistics?.viewCount ?? ""
        let videoCount = statistics?.videoCount ?? ""
        
        return SubscriptionDetailView.Item(id: id, title: snippet.title, subtitle: snippet.description, imagePath: snippet.thumbnails["high"]?.url, viewCount: Int(viewCount) ?? 0, videoCount: Int(videoCount) ?? 0)
    }
}


extension ContentView.Destination: FlowDestination {
    var title: String? {
        switch self {
        case .splashScreen, .login, .main:
            nil
        case .subscriptionList:
            String(localized: LocalizedStringResource("Subscriptions"))
        case .subscriptionDetail(let title, _):
            title
        case .account:
            String(localized: LocalizedStringResource("Account"))
        }
    }
    
    var icon: Image? {
        switch self {
        case .splashScreen, .login, .main, .subscriptionDetail:
            nil
        case .subscriptionList:
            Image(systemName: "gearshape.fill")
        case .account:
            Image(systemName: "person.crop.circle.fill")
        }
    }
}
