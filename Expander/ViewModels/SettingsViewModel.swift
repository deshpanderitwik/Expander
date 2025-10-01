//
//  SettingsViewModel.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var systemPrompt: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(systemPrompt: String = "") {
        self.systemPrompt = systemPrompt
    }
    
    // MARK: - Public Interface
    
    func updateSystemPrompt(_ newPrompt: String) {
        systemPrompt = newPrompt
    }
    
    func dismiss() {
        // Focus management is handled by the view
    }
}
