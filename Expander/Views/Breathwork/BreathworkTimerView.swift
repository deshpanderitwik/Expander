//
//  BreathworkTimerView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI

struct BreathworkTimerView: View {
    let isCompact: Bool
    @StateObject private var viewModel = BreathworkTimerViewModel()
    
    var body: some View {
        VStack(spacing: isCompact ? 24 : 64) {
            // Phase label
            Text(viewModel.currentPhase)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
            
            // Circular timer
            ZStack {
                Circle()
                    .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 2)
                    .frame(width: isCompact ? 120 : 200, height: isCompact ? 120 : 200)
                
                Text("\(viewModel.remainingSeconds)")
                    .font(.system(size: isCompact ? 50 : 100, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Progress dots (only in full version)
            if !isCompact {
                HStack(spacing: 12) {
                    ForEach(0..<10, id: \.self) { index in
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(index < viewModel.currentCycle ? Color(red: 1.0, green: 0.23, blue: 0.19) : .gray)
                    }
                }.padding(.top, 24)
            }
            
            // Control buttons - always show both
            HStack(spacing: isCompact ? 20 : 32) {
                // Play/Pause button
                Button(action: {
                    viewModel.toggleTimer()
                }) {
                    Image(systemName: viewModel.isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                        .frame(width: isCompact ? 36 : 60, height: isCompact ? 36 : 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 2)
                        )
                }
                
                // Stop button
                Button(action: {
                    viewModel.stopTimer()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                        .foregroundColor(viewModel.isActive ? Color(red: 1.0, green: 0.23, blue: 0.19) : Color.gray.opacity(0.3))
                        .frame(width: isCompact ? 36 : 60, height: isCompact ? 36 : 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(viewModel.isActive ? Color(red: 1.0, green: 0.23, blue: 0.19) : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                }
                .disabled(!viewModel.isActive)
            }
            .padding(.top, isCompact ? 8 : 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
        .onDisappear {
            viewModel.stopTimer()
        }
    }
}
