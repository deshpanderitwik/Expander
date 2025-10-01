//
//  CompactBreathworkTimerView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI

struct CompactBreathworkTimerView: View {
    @State private var currentPhase = "Breathe In"
    @State private var remainingSeconds = 1
    @State private var currentCycle = 0
    @State private var timer: Timer?
    @State private var isCountingUp = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 16) {
                // Compact circular timer
                VStack(spacing: 12) {
                    Text(currentPhase)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                    
                    ZStack {
                        Circle()
                            .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 2)
                            .frame(width: 60, height: 60)
                        
                        Text("\(remainingSeconds)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            // Reset timer to beginning state every time it appears
            resetTimer()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isCountingUp {
                // Counting up (Breathe In: 1→4, Hold: 1→7)
                if currentPhase == "Breathe In" && remainingSeconds < 4 {
                    remainingSeconds += 1
                } else if currentPhase == "Hold" && remainingSeconds < 7 {
                    remainingSeconds += 1
                } else {
                    nextPhase()
                }
            } else {
                // Counting down (Breathe Out: 8→1)
                if remainingSeconds > 1 {
                    remainingSeconds -= 1
                } else {
                    nextPhase()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        // Reset to beginning state
        currentPhase = "Breathe In"
        remainingSeconds = 1
        isCountingUp = true
    }
    
    private func nextPhase() {
        // Breathwork phase cycling with specific countdown patterns
        switch currentPhase {
        case "Breathe In":
            currentPhase = "Hold"
            remainingSeconds = 1
            isCountingUp = true
        case "Hold":
            currentPhase = "Breathe Out"
            remainingSeconds = 8
            isCountingUp = false
        case "Breathe Out":
            currentPhase = "Breathe In"
            remainingSeconds = 1
            isCountingUp = true
        default:
            currentPhase = "Breathe In"
            remainingSeconds = 1
            isCountingUp = true
        }
    }
}
