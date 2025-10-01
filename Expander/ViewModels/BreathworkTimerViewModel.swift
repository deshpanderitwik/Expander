//
//  BreathworkTimerViewModel.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI
import Combine

@MainActor
class BreathworkTimerViewModel: ObservableObject {
    @Published var currentPhase = "Ready"
    @Published var remainingSeconds = 0
    @Published var currentCycle = 0
    @Published var isActive = false
    @Published var isCountingUp = false
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize with ready state
        resetToReady()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    func toggleTimer() {
        if isActive {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleTimerTick()
            }
        }
    }
    
    func pauseTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    func stopTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
        resetToReady()
    }
    
    func resetToReady() {
        currentPhase = "Ready"
        remainingSeconds = 0
        isCountingUp = false
        currentCycle = 0
    }
    
    // MARK: - Private Methods
    
    private func handleTimerTick() {
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
    
    private func nextPhase() {
        // Breathwork phase cycling with specific countdown patterns
        switch currentPhase {
        case "Ready":
            currentPhase = "Breathe In"
            remainingSeconds = 1
            isCountingUp = true
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
            currentCycle += 1
        default:
            resetToReady()
        }
    }
}
