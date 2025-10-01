//
//  FooterWithGradient.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI

struct FooterWithGradient<Content: View>: View {
    let gradientHeight: CGFloat
    let gradientOffset: CGFloat
    let gradientColors: [Color]
    @ViewBuilder let content: () -> Content
    
    init(
        gradientHeight: CGFloat = 24,
        gradientOffset: CGFloat = 16, // Fixed offset from footer top
        gradientColors: [Color] = [.black.opacity(0.9), .black.opacity(0.6), .black.opacity(0.2), .clear],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.gradientHeight = gradientHeight
        self.gradientOffset = gradientOffset
        self.gradientColors = gradientColors
        self.content = content
    }
    
    var body: some View {
        content()
            .overlay(
                // Gradient positioned relative to footer top
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: gradientHeight)
                .offset(y: gradientOffset) // Negative offset moves gradient up from footer
                .allowsHitTesting(false),
                alignment: .top // Align to footer top
            )
    }
}
