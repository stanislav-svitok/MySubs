//
//  Watermark.swift
//  MySubs
//
//  Created by Stanislav Svitok on 24/01/2025.
//

import SwiftUI
import NavigationFlow

/// Just an example modifier to demonstrate automatic forwarding of onSubmit() modifier
public struct Watermark: ViewModifier {
    var text: String

    public func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
            Text(text)
                .font(.caption)
                .foregroundStyle(.white)
                .padding(5)
                .background(.black)
                .opacity(0.5)
        }
    }
}

extension ActionSubmitView {
    public func watermarked(with text: String) -> ModifiedContent<Self, Watermark> {
        modifier(Watermark(text: text))
    }
}
