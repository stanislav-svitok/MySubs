//
//  HoldModifier.swift
//  MySubs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import SwiftUI

extension View {
    func onPressHold(_ onChange: @escaping (HoldModifier.HoldState) -> Void) -> some View {
        ModifiedContent(content: self, modifier:HoldModifier(onChange: onChange))
    }
}

struct HoldModifier: ViewModifier {

    enum HoldState {
        case started
        case finished
        case cancelled
    }
    
    let onChange: (HoldState) -> Void
    
    @GestureState private var isPressing = false
    @State private var didDrag = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.3)
                .sequenced(before: DragGesture())
                .updating($isPressing) { value, state, _ in
                    switch value {
                    case .second(true, nil):
                        didDrag = false
                        state = true
                        
                    case .second(true, _):
                        guard !didDrag else { return }
                        state = false
                        didDrag = true
                        
                    default:
                        break
                    }
                })
            .onChange(of: isPressing) { newValue in
                if newValue {
                    onChange(.started)
                } else if didDrag {
                    onChange(.cancelled)
                } else {
                    onChange(.finished)
                }
            }
    }
}
