//
//  BreathworkView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI

struct BreathworkView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            CustomHeaderView()
            
            // Full breathwork timer
            BreathworkTimerView(isCompact: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.startLocation.x < 50 && value.translation.width > 100 {
                        dismiss()
                    }
                }
        )
    }
}
