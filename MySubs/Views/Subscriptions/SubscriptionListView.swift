//
//  SubscriptionsView.swift
//  MySubs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import SwiftUI
import NavigationFlow

struct SubscriptionListView: ActionSubmitView {
    enum Action: SubmitAction {
        case refreshContent(Binding<[Item]>, page: Binding<String?>)
        case select(Item)
    }
    
    enum ContentState: Equatable {
        case loading
        case list
        case error(message: String)
    }
    
    struct Item: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let imagePath: String?
    }

    @EnvironmentAction var submit: (Action) async throws -> Void
    @State private var state: ContentState = .loading
    
    
    @State private var isLoadingMore: Bool = false
    @State private var nextPage: String? = nil
    
    @State private var items: [Item] = []
    
    @State private var disabled: Bool = false
    
    var body: some View {
        VStack {
            switch state {
            case .loading:
                ProgressView()
                    .progressViewStyle(.regular)
                    .foregroundStyle(Color.blue)
                    .fixedSize()
                    .onAppear {
                        Task { @MainActor in
                            await loadSubscriptions()
                        }
                    }
                
            case .error(let error):
                VStack {
                    Text("Failed to load subscriptions")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                    
                    Button {
                        state = .loading
                        await loadSubscriptions()
                    } label: {
                        Text("Retry")
                    }
                    
                }
                
            case .list:
                List {
                    ForEach(items) { item in
                        SubscriptionItemView(title: item.title, subtitle: item.subtitle, imagePath: item.imagePath, didSelect: {
                            disabled = true
                            try await submit(.select(item))
                            disabled = false
                        })
                    }
                    
                    if let nextPage {
                        ProgressView()
                            .id(nextPage)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .onAppear {
                                guard !isLoadingMore else {
                                    return
                                }
                                isLoadingMore = true
                                
                                Task { @MainActor in
                                    await loadMoreSubscriptions()
                                    isLoadingMore = false
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadSubscriptions()
                }
                .disabled(disabled)
            }
        }
        .animation(.default, value: state)
    }
    
    @MainActor private func loadSubscriptions() async {
        do {
            try await submit(.refreshContent(_items.projectedValue, page: _nextPage.projectedValue))
            state = .list
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
    
    @MainActor private func loadMoreSubscriptions() async {
        do {
            try await submit(.refreshContent(_items.projectedValue, page: _nextPage.projectedValue))
            state = .list
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
}

#Preview {
    SubscriptionListView()
        .onSubmit { action -> NavigationAction<EmptyDestination> in
            switch action {
            case .refreshContent(let items, page: let page):
                items.wrappedValue = items.wrappedValue + [
                    .init(id: UUID().uuidString, title: UUID().uuidString, subtitle: UUID().uuidString, imagePath: nil)
                ]
                
                return .keep
                
            case .select:
                return .keep
            }
        }
}
