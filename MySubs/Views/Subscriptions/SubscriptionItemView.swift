//
//  SubscriptionItemView.swift
//  MySubs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import SwiftUI

struct SubscriptionItemView: View {
    
    let title: String
    let subtitle: String
    let imagePath: String?
    let didSelect: (() async throws  -> Void)?
    
    @State private var isPressing = false
    
    private let rowHeight: CGFloat = 90.0
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.backgroud
            
            if isPressing {
                Color.gray.opacity(0.1)
            }
            
            HStack(alignment: .top)  {
                if let imagePath {
                    AsyncImage(url: URL(string: imagePath)){ image in
                        image.resizable()
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: rowHeight, height: rowHeight)
                } else {
                    Rectangle()
                        .foregroundStyle(Color.gray)
                        .frame(width: rowHeight, height: rowHeight)
                }
                
                VStack(alignment: .leading) {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(.headline)
                    
                    if subtitle.isEmpty {
                        Text("No description")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        Text(subtitle)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.blue)
                    .frame(height: rowHeight, alignment: .center)
            }
            .frame(height: rowHeight, alignment: .center)
            .padding()
            .scaleEffect(isPressing ? 0.97 : 1.0)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
        .onTapGesture {
            try? await didSelect?()
        }
        .onPressHold { state in
            withAnimation {
                switch state {
                case .started:
                    isPressing = true
                    
                case .finished:
                    isPressing = false
                    Task { @MainActor in try? await didSelect?() }
                    
                case .cancelled:
                    isPressing = false
                }
            }
        }
    }
}

#Preview {
    SubscriptionItemView(title: "Title", subtitle: "Lorem ipsum dolor sit amet", imagePath: nil, didSelect: nil)
}
