//
//  SubscriptionDetailView.swift
//  MySubs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import NavigationFlow
import SwiftUI

struct SubscriptionDetailView: ActionSubmitView {
    enum Action: SubmitAction {
        case refreshContent(Binding<Item>)
    }
    
    enum ContentState: Equatable {
        case loading
        case detail
        case error(message: String)
    }
    
    struct Item: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let imagePath: String?
        
        let viewCount: Int
        let videoCount: Int
        
        static let empty = Item(id: "", title: "", subtitle: "", imagePath: "", viewCount: 0, videoCount: 0)
    }
    
    @State private var item: Item = Item.empty
    @State private var state: ContentState = .loading
    
    @EnvironmentAction var submit: (Action) async throws -> Void
    
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
                            await loadDetail()
                        }
                    }
                
            case .error(let error):
                VStack {
                    Text("Failed to load detail")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                    
                    Button {
                        state = .loading
                        await loadDetail()
                    } label: {
                        Text("Retry")
                    }
                    
                }
                
            case .detail:
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let imagePath = item.imagePath {
                            AsyncImage(url: URL(string: imagePath)) { result in
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
                        }
                        
                        HStack {
                            Text("\(item.videoCount) videos")
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            
                            Divider()
                                .overlay(Color.white)
                            
                            Text("\(item.viewCount) views")
                                .frame(maxWidth: .infinity, alignment: .center)

                        }
                        .foregroundStyle(Color.white)
                        .padding()
                        
                        .background(Color.gray)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text(item.title)
                                .font(.title)
                            
                            Text(item.subtitle)
                                .font(.body)
                        }
                        .padding()
                        
                    }
                }
            }
        }
        .animation(.default, value: state)
    }
    
    @MainActor private func loadDetail() async {
        do {
            try await submit(.refreshContent(_item.projectedValue))
            state = .detail
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
}

#Preview {
    SubscriptionDetailView()
}
