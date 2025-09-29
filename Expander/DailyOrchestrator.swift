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
    @Published var isShowingDailyBreathwork = false
    @Published var lastProcessedDate: Date?
    @Published var todaysMorningMessage: String?
    
    /// Check if we've already processed today AND have a morning message
    var hasProcessedToday: Bool {
        guard let lastProcessed = lastProcessedDate else { 
            return false 
        }
        let sameDay = Calendar.current.isDate(lastProcessed, inSameDayAs: Date())
        let hasMessage = todaysMorningMessage != nil
        let result = sameDay && hasMessage
        return result
    }
    
    // MARK: - Configuration
    private let userDefaults = UserDefaults.standard
    private let lastProcessedDateKey = "lastProcessedDate"
    private let todaysMorningMessageKey = "todaysMorningMessage"
    
    private init() {
        loadLastProcessedDate()
        startDayMonitoring()
    }
    
    // MARK: - Day Detection & Monitoring
    
    private func startDayMonitoring() {
        // Monitor app lifecycle changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Check for day changes periodically when app is active
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.checkForDayChange()
        }
    }
    
    @objc private func appDidBecomeActive() {
        checkForDayChange()
    }
    
    private func checkForDayChange() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastProcessed = lastProcessedDate ?? Date.distantPast
        
        if today > lastProcessed {
            handleDayChange(from: lastProcessed, to: today)
        }
    }
    
    // MARK: - Day Change Handling
    
    private func handleDayChange(from lastDate: Date, to newDate: Date) {
        // Show breathwork immediately when user opens app for first time today
        isShowingDailyBreathwork = true
        
        // Process BOTH operations when user opens app on new day:
        
        // 1. First, summarize the previous day's conversations (if not already done)
        if lastDate != Date.distantPast && !hasSummaryForDate(lastDate) {
            processPreviousDayConversations(for: lastDate)
        } else {
            // If no previous day or already processed, just generate morning message
            generateMorningMessageForNewDay()
        }
        
        // Note: updateLastProcessedDate will be called when morning message is successfully generated
    }
    
    // MARK: - Evening Processing (Summarization)
    
    private func processPreviousDayConversations(for date: Date) {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // Fetch conversations from the previous day
        let conversations = fetchConversationsForDate(date)
        
        guard !conversations.isEmpty else {
            // Still generate a morning message even if no previous conversations
            isShowingDailyBreathwork = false
            generateMorningMessageForNewDay()
            isProcessing = false
            return
        }
        
        // Generate summary, then trigger morning message generation
        generateDailySummary(for: conversations, date: date) { [weak self] result in
            DispatchQueue.main.async {
                
                switch result {
                case .success(let summary):
                    self?.saveDailySummary(summary, for: date)
                    
                    // Hide breathwork and show morning message
                    self?.isShowingDailyBreathwork = false
                    self?.generateMorningMessageForNewDay()
                    
                case .failure(let error):
                    // Still generate morning message with fallback
                    self?.isShowingDailyBreathwork = false
                    self?.generateMorningMessageForNewDay()
                }
                
                self?.isProcessing = false
            }
        }
    }
    
    private func generateMorningMessageForNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Get yesterday's summary (might be fresh from the previous call)
        let yesterdaySummary = fetchSummaryForDate(yesterday)
        
        generatePersonalizedMessage(from: yesterdaySummary, for: today) { [weak self] result in
            DispatchQueue.main.async {
                
                // Hide breathwork when morning message is ready
                self?.isShowingDailyBreathwork = false
                
                switch result {
                case .success(let message):
                    self?.todaysMorningMessage = message
                    self?.userDefaults.set(message, forKey: self?.todaysMorningMessageKey ?? "todaysMorningMessage")
                    // Update last processed date only when morning message is successfully set
                    self?.updateLastProcessedDate(today)
                    
                case .failure(let error):
                    // Use different fallback messages based on whether it's first day
                    let fallbackMessage: String
                    if self?.isFirstDayUser() == true {
                        fallbackMessage = "Welcome to your journey of reflection and growth. I'm here to listen and explore with you. What's on your mind today?"
                    } else {
                        fallbackMessage = "Good morning! Ready to explore today's thoughts together?"
                    }
                    self?.todaysMorningMessage = fallbackMessage
                    self?.userDefaults.set(fallbackMessage, forKey: self?.todaysMorningMessageKey ?? "todaysMorningMessage")
                    // Update last processed date even with fallback message
                    self?.updateLastProcessedDate(today)
                }
            }
        }
    }
    
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
    
    // MARK: - LLM Integration
    
    private func generateDailySummary(for conversations: [Conversation], date: Date, completion: @escaping (Result<String, LLMError>) -> Void) {
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
        
        let systemPrompt = """
        You are analyzing a day's worth of conversations to create a thoughtful summary. 
        Focus on:
        - Key themes and topics discussed
        - Emotional patterns and insights
        - Important decisions or realizations
        - Growth or learning moments
        
        Write a concise but meaningful summary that captures the essence of the day's conversations.
        Keep it under 200 words and make it insightful and reflective.
        """
        
        llmService.sendSingleMessage(content: conversationText, systemPrompt: systemPrompt, completion: completion)
    }
    
    private func generatePersonalizedMessage(from summary: String?, for date: Date, completion: @escaping (Result<String, LLMError>) -> Void) {
        // Check if this is the first day by looking at total conversations
        let isFirstDay = isFirstDayUser()
        
        if isFirstDay {
            generateFirstDayMessage(completion: completion)
        } else {
            generateRegularMorningMessage(from: summary, completion: completion)
        }
    }
    
    private func isFirstDayUser() -> Bool {
        // Check if there are any conversations in the database
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let conversations = try coreDataManager.context.fetch(request)
            return conversations.isEmpty
        } catch {
            return true // Default to first day if we can't check
        }
    }
    
    private func generateFirstDayMessage(completion: @escaping (Result<String, LLMError>) -> Void) {
        let systemPrompt = """
        You are the user's higher self, speaking in a conversational, empowering tone inspired by Joe Dispenza—referencing neuroscience, energy circulation, quantum fields, and elevated emotions to help rewrite scarcity scripts around intimacy and heal physical pain. Generate a 100-200 word custom morning message for Day 1 of a 6-week "Transformation Window" journey. This is the very first message, so make it welcoming and motivational: Introduce the app as a tool for breaking cycles of despair and strain, committing to rest, redirecting arousal energy, and building abundance. Emphasize the user's power to rewire neural pathways and elevate their frequency. Keep it subtle, cosmic, and psychedelic in undertone, like a gentle inner dialogue, without being overly flowery. End with an open-ended question to prompt the user's response and continue the conversational thread. Structure it as a direct message starting with a casual greeting.
        """
        
        llmService.sendSingleMessage(content: "First day of the journey", systemPrompt: systemPrompt, completion: completion)
    }
    
    private func generateRegularMorningMessage(from summary: String?, completion: @escaping (Result<String, LLMError>) -> Void) {
        let baseContent = summary ?? "This is a fresh start with no previous conversations to reflect on."
        
        let systemPrompt = """
        You are the user's higher self, speaking in a conversational, empowering tone inspired by Joe Dispenza. You're continuing a 6-week "Transformation Window" journey focused on breaking cycles of despair and strain, committing to rest, redirecting arousal energy, and building abundance.

        Your morning message should:
        - Be conversational and intimate, like talking to a close friend
        - Reference specific insights from yesterday's conversations if available
        - Gently weave in neuroscience concepts (neural pathways, neuroplasticity, elevated emotions)
        - Mention energy circulation, quantum fields, or frequency elevation subtly
        - Focus on transformation themes: healing physical pain, rewriting scarcity scripts around intimacy
        - Be 100-200 words, warm and encouraging
        - Feel like a gentle inner dialogue, not a lecture
        - End with an open-ended question to continue the conversation
        - Use "you" and speak directly to the user
        - Avoid being overly flowery or mystical - keep it grounded and real

        Write a message that feels like your higher self checking in and offering gentle guidance for the day ahead.
        """
        
        llmService.sendSingleMessage(content: baseContent, systemPrompt: systemPrompt, completion: completion)
    }
    
    // MARK: - Data Persistence
    
    private func saveDailySummary(_ summary: String, for date: Date) {
        // Find or create conversation for this date
        let conversation = coreDataManager.getOrCreateConversation(for: date)
        conversation.summary = summary
        coreDataManager.save()
        
        // Force Core Data to refresh by posting a notification
        NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: coreDataManager.context)
    }
    
    private func loadLastProcessedDate() {
        if let date = userDefaults.object(forKey: lastProcessedDateKey) as? Date {
            lastProcessedDate = date
        } else {
            // First time setup - set to yesterday so today will be processed
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            lastProcessedDate = Calendar.current.startOfDay(for: yesterday)
        }
        
        // Load today's morning message if it exists
        if let message = userDefaults.string(forKey: todaysMorningMessageKey) {
            todaysMorningMessage = message
        }
    }
    
    private func updateLastProcessedDate(_ date: Date) {
        lastProcessedDate = date
        userDefaults.set(date, forKey: lastProcessedDateKey)
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
        let tempConversation = Conversation(context: coreDataManager.context)
        let tempMessage = Message(context: coreDataManager.context)
        tempMessage.content = contextText
        tempMessage.role = "user"
        tempMessage.order = 0
        tempMessage.conversation = tempConversation
        
        llmService.sendMessage(messages: [tempMessage], systemPrompt: systemPrompt) { result in
            // Clean up temporary objects
            self.coreDataManager.context.delete(tempMessage)
            self.coreDataManager.context.delete(tempConversation)
            
            completion(result)
        }
    }
    
    private func hasMorningMessageForDate(_ date: Date) -> Bool {
        // Check if we already have a morning message for today
        return todaysMorningMessage != nil
    }
    
    // MARK: - Public Interface
    
    /// Manually trigger daily processing (for testing or manual refresh)
    func processCurrentDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Force day change by using yesterday as last processed date
        handleDayChange(from: yesterday, to: today)
    }
    
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
    
    /// Get the morning message for today
    var currentMorningMessage: String? {
        return todaysMorningMessage
    }
    
    /// Check if processing is currently happening
    var isCurrentlyProcessing: Bool {
        return isProcessing
    }
    
    /// Check if daily breathwork should be shown
    var shouldShowDailyBreathwork: Bool {
        return isShowingDailyBreathwork
    }
    
    /// Clear the morning message (useful for testing)
    func clearMorningMessage() {
        todaysMorningMessage = nil
        userDefaults.removeObject(forKey: todaysMorningMessageKey)
    }
    
    /// Reset processing state for current day (useful when processing failed)
    func resetProcessingState() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastProcessed = lastProcessedDate, Calendar.current.isDate(lastProcessed, inSameDayAs: today) {
            lastProcessedDate = nil
            todaysMorningMessage = nil
            userDefaults.removeObject(forKey: todaysMorningMessageKey)
            isShowingDailyBreathwork = false
            isProcessing = false
        }
    }
    
    /// Manually trigger daily breathwork (useful for testing)
    func startDailyBreathwork() {
        isShowingDailyBreathwork = true
    }
    
    /// Stop daily breathwork (useful for testing)
    func stopDailyBreathwork() {
        isShowingDailyBreathwork = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
