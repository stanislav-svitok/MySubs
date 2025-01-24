//
//  ProgressView.swift
//  MSs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import SwiftUI

enum MSConfigurableProgressStyleType {
    case regular
    case big
}

struct MSProgressViewStyle: ProgressViewStyle {
    let style: MSConfigurableProgressStyleType

    @State
    private var from = 10.0

    @State
    private var to = 359.0

    @State
    private var rotation = 0.0
    
    @State
    private var isAnimating = false
    
    @State
    private var isRotating = false

    func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted

        return ZStack {
            if let fractionCompleted {
                Circle()
                    .trim(from: 0.1, to: fractionCompleted)
                    .stroke(.foreground, style: StrokeStyle(lineWidth: style.strokeWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(idealWidth: style.size.width, idealHeight: style.size.height)
            } else {
                Arc(startAngle: from, endAngle: to, clockwise: false)
                    .stroke(.foreground, style: StrokeStyle(lineWidth: style.strokeWidth, lineCap: .round))
                    .frame(idealWidth: style.size.width, idealHeight: style.size.height)
                    .rotationEffect(.degrees(rotation))
                    .task {
                        guard !isAnimating else {
                            return
                        }
                        
                        isAnimating = true
                        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                            from += (360 * 4) - 12
                            to += 360 * 2
                        }
                    }
                    .onAppear {
                        guard !isRotating else {
                            return
                        }
                        
                        isRotating = true
                        withAnimation(.linear(duration: 5)
                            .repeatForever(autoreverses: false)) {
                                rotation = 360.0
                            }
                    }
            }
        }
    }
}

struct Arc: Shape {
    var startAngle: Double
    var endAngle: Double
    var clockwise: Bool

    public init(startAngle: Double, endAngle: Double, clockwise: Bool) {
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.clockwise = clockwise
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: Angle.degrees(startAngle.truncatingRemainder(dividingBy: 360)), endAngle: Angle.degrees(endAngle.truncatingRemainder(dividingBy: 360)), clockwise: (startAngle - endAngle).truncatingRemainder(dividingBy: 360) > 0)

        return path
    }

    public var animatableData: AnimatablePair<Double, Double> {
        get {
           AnimatablePair(startAngle, endAngle)
        }

        set {
            startAngle = newValue.first
            endAngle = newValue.second
        }
    }
}

extension MSConfigurableProgressStyleType {
    var strokeWidth: CGFloat {
        switch self {
        case .regular:
            return 2
        case .big:
            return 4
        }
    }

    var lineCap: CGLineCap {
        .square
    }
    
    var size: CGSize {
        switch self {
        case .regular:
            return CGSize(width: 24, height: 24)
        case .big:
            return CGSize(width: 64, height: 64)
        }
    }
}

extension ProgressView {
    func progressViewStyle(_ style: MSConfigurableProgressStyleType) -> some View {
        self.progressViewStyle(MSProgressViewStyle(style: style))
    }
}
