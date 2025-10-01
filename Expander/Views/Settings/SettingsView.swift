//
//  SettingsView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var systemPrompt: String
    @StateObject private var viewModel: SettingsViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    init(systemPrompt: Binding<String>) {
        self._systemPrompt = systemPrompt
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(systemPrompt: systemPrompt.wrappedValue))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            CustomHeaderView()
            
            // Content area with gradient overlays
            ZStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 20) {
                    // System prompt section with gradient overlay
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System prompt")
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        TextEditor(text: $viewModel.systemPrompt)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .padding(.top, 4) // Push text content below gradient
                            .focused($isTextFieldFocused)
                            .lineSpacing(5) // Adjust line height here
                    }
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black,
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 24)
                        .offset(y: 32) // Position after the title
                        .allowsHitTesting(false),
                        alignment: .top
                    )
                    
                    Spacer()
                }
                
            }
            
            // Settings Footer with Gradient
            FooterWithGradient(gradientHeight: 24, gradientOffset: -52) {
                HStack(alignment: .top, spacing: 0) {
                    Button(action: {
                        // Update system prompt action
                        systemPrompt = viewModel.systemPrompt
                        dismiss()
                    }) {
                        Text("Update")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 0)
                .padding(.bottom, 16)
            }
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
