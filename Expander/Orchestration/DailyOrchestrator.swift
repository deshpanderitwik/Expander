//
//  DailyOrchestrator.swift
//  Expander
//
//  Created by Rit on 9/14/25.
//

import Foundation
import SwiftUI
import CoreData

/// Orchestrates daily conversation summaries and morning messages
class DailyOrchestrator: ObservableObject {
    static let shared = DailyOrchestrator()
    
    // MARK: - Dependencies
    private let coreDataManager = CoreDataManager.shared
    private let llmService = LLMService.shared
    
    // MARK: - State
    @Published var isProcessing = false
    
    private init() {
        // Simplified initialization - no day monitoring needed
    }
    
    // MARK: - Summary Generation Only
    
    // MARK: - Data Fetching
    
    private func fetchConversationsForDate(_ date: Date) -> [Conversation] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try coreDataManager.context.fetch(request)
        } catch {
            return []
        }
    }
    
    private func fetchSummaryForDate(_ date: Date) -> String? {
        let conversation = coreDataManager.fetchConversation(for: date)
        return conversation?.summary
    }
    
    // MARK: - LLM Integration for Summaries Only
    
    // MARK: - Data Persistence
    
    private func saveDailySummary(_ summary: String, for date: Date) {
        // Find or create conversation for this date
        let conversation = coreDataManager.getOrCreateConversation(for: date)
        conversation.summary = summary
        coreDataManager.save()
        
        // Force Core Data to refresh by posting a notification
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: self.coreDataManager.context)
        }
    }
    
    // MARK: - State Checking
    
    private func hasSummaryForDate(_ date: Date) -> Bool {
        let conversation = coreDataManager.fetchConversation(for: date)
        return conversation?.summary?.isEmpty == false
    }
    
    // MARK: - Missing Summary Generation
    
    private func getConversationsNeedingSummaries() -> [Conversation] {
        let allConversations = coreDataManager.fetchAllConversations()
        return allConversations
            .filter { conversation in
                // Only include conversations that have messages but no summary
                conversation.hasMessages && 
                (conversation.summary?.isEmpty ?? true)
            }
            .sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
    }
    
    private func processSummariesInChronologicalOrder(_ conversations: [Conversation], currentIndex: Int) {
        guard currentIndex < conversations.count else {
            // All summaries processed
            isProcessing = false
            return
        }
        
        let conversation = conversations[currentIndex]
        let date = conversation.date ?? Date.distantPast
        
        // Get the previous day's summary for context
        let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? Date.distantPast
        let previousSummary = fetchSummaryForDate(previousDate)
        
        // Generate summary with context
        generateDailySummaryWithContext(for: [conversation], date: date, previousSummary: previousSummary) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let summary):
                    self?.saveDailySummary(summary, for: date)
                    // Continue with next conversation
                    self?.processSummariesInChronologicalOrder(conversations, currentIndex: currentIndex + 1)
                    
                case .failure(let error):
                    // Continue with next conversation even if this one failed
                    self?.processSummariesInChronologicalOrder(conversations, currentIndex: currentIndex + 1)
                }
            }
        }
    }
    
    private func generateDailySummaryWithContext(for conversations: [Conversation], date: Date, previousSummary: String?, completion: @escaping (Result<String, LLMError>) -> Void) {
        // Prepare conversation content
        let conversationText = conversations.compactMap { conversation in
            guard let messages = conversation.messages?.allObjects as? [Message] else { return nil }
            let sortedMessages = messages.sorted { $0.order < $1.order }
            return sortedMessages.compactMap { message in
                let role = message.displayRole
                let content = message.safeContent.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !content.isEmpty else { return nil }
                return "\(role): \(content)"
            }.joined(separator: "\n")
        }.filter { !$0.isEmpty }.joined(separator: "\n\n---\n\n")
        
        // Ensure we have content to send
        guard !conversationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(.invalidMessageFormat))
            return
        }
        
        // Build context from previous day's summary
        let contextText: String
        if let previousSummary = previousSummary, !previousSummary.isEmpty {
            contextText = "Previous day's summary:\n\(previousSummary)\n\nToday's conversations:\n\(conversationText)"
        } else {
            contextText = conversationText
        }
        
        let systemPrompt = """
        You are creating a daily conversation summary. Your response should be formatted as a clear, concise summary of the day's chat.
        
        FORMAT YOUR RESPONSE AS:
        A single paragraph that summarizes the day's conversations in a natural, flowing way.
        
        INCLUDE:
        - Key themes and topics that were discussed
        - Emotional patterns and insights that emerged
        - Important decisions, realizations, or breakthroughs
        - Growth moments or learning experiences
        - How today's conversations connect to previous days (if context is provided)
        
        WRITING STYLE:
        - Write in a reflective, thoughtful tone
        - Use complete sentences and natural flow
        - Avoid bullet points or lists
        - Make it read like a summary paragraph someone would write about their day
        - Keep it under 200 words
        - Focus on the most meaningful aspects of the conversations
        
        Your response should sound like: "Today's conversations explored themes of [topic], with moments of [insight]. The discussion revealed [realization] and highlighted [growth moment]..."
        """
        
        // Create a temporary message object to use with the regular sendMessage method
        // This ensures we use the same retry logic and request format as regular conversations
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = coreDataManager.context
        
        let tempConversation = Conversation(context: backgroundContext)
        let tempMessage = Message(context: backgroundContext)
        tempMessage.content = contextText
        tempMessage.role = "user"
        tempMessage.order = 0
        tempMessage.conversation = tempConversation
        
        llmService.sendMessage(messages: [tempMessage], systemPrompt: systemPrompt) { result in
            // Clean up temporary objects in background context
            backgroundContext.delete(tempMessage)
            backgroundContext.delete(tempConversation)
            
            completion(result)
        }
    }
    
    
    // MARK: - Public Interface
    
    /// Generate summary for a specific date
    func generateSummaryForDate(_ date: Date) {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // Get conversations for this specific date
        let conversations = fetchConversationsForDate(date)
        
        guard !conversations.isEmpty else {
            isProcessing = false
            return
        }
        
        // Check if summary already exists
        if !hasSummaryForDate(date) {
            // Get the previous day's summary for context
            let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? Date.distantPast
            let previousSummary = fetchSummaryForDate(previousDate)
            
            // Generate summary with context
            generateDailySummaryWithContext(for: conversations, date: date, previousSummary: previousSummary) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let summary):
                        self?.saveDailySummary(summary, for: date)
                    case .failure(let error):
                        // Handle error silently for privacy
                        break
                    }
                    
                    self?.isProcessing = false
                }
            }
        } else {
            isProcessing = false
        }
    }
    
    /// Generate summaries for all existing conversations that don't have them (legacy function)
    func generateMissingSummaries() {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // Get all conversations that need summaries, sorted by date
        let conversationsNeedingSummaries = getConversationsNeedingSummaries()
        
        guard !conversationsNeedingSummaries.isEmpty else {
            isProcessing = false
            return
        }
        
        // Process summaries in chronological order to maintain continuity
        processSummariesInChronologicalOrder(conversationsNeedingSummaries, currentIndex: 0)
    }
    
    /// Check if processing is currently happening
    var isCurrentlyProcessing: Bool {
        return isProcessing
    }
}
