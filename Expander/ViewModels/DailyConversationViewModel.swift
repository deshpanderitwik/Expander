//
//  DailyConversationViewModel.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI
import CoreData
import Combine

@MainActor
class DailyConversationViewModel: ObservableObject {
    @Published var conversation: Conversation?
    @Published var isLoading = false
    
    private let date: Date
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(date: Date) {
        self.date = date
        setupConversationFetch()
    }
    
    // MARK: - Public Interface
    
    var isElapsed: Bool {
        date < Date()
    }
    
    var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    var isFuture: Bool {
        date > Date()
    }
    
    var dayNumber: Int {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!)
        let dayDiff = calendar.dateComponents([.day], from: startDate, to: calendar.startOfDay(for: date)).day!
        return dayDiff
    }
    
    var hasMessages: Bool {
        conversation?.hasMessages ?? false
    }
    
    var hasSummary: Bool {
        guard let summary = conversation?.summary else { return false }
        return !summary.isEmpty
    }
    
    var sortedMessages: [Message] {
        conversation?.sortedMessages ?? []
    }
    
    func generateSummary() {
        DailyOrchestrator.shared.generateSummaryForDate(date)
    }
    
    func clearSummary() {
        guard let conversation = conversation else { return }
        conversation.summary = nil
        coreDataManager.save()
    }
    
    // MARK: - Private Methods
    
    private func setupConversationFetch() {
        // Fetch conversation for the given date
        conversation = coreDataManager.fetchConversation(for: date)
        
        // Listen for Core Data changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.conversation = self?.coreDataManager.fetchConversation(for: self?.date ?? Date())
                }
            }
            .store(in: &cancellables)
    }
}
