//
//  ChatViewModel.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI
import CoreData

@MainActor
class ChatViewModel: ObservableObject {
    @Published var currentConversation: Conversation?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataManager = CoreDataManager.shared
    private let llmService = LLMService.shared
    
    func setupCurrentConversation() {
        let today = Date()
        
        // Use start of day to ensure consistent date matching
        let calendar = Calendar.current
        let normalizedToday = calendar.startOfDay(for: today)
        currentConversation = coreDataManager.getOrCreateConversation(for: normalizedToday)
    }
    
    func sendMessage(_ text: String, systemPrompt: String?) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let conversation = currentConversation else { return }
        
        // Add user message
        _ = coreDataManager.addMessage(to: conversation, content: text, role: "user")
        
        // Clear error message
        errorMessage = nil
        
        // Set loading state
        isLoading = true
        
        // Send message to LLM service
        llmService.sendMessage(
            messages: conversation.sortedMessages,
            systemPrompt: systemPrompt
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    // Add AI response to conversation
                    _ = self.coreDataManager.addMessage(to: conversation, content: response, role: "ai")
                    
                case .failure(let error):
                    // Show user-friendly error message
                    self.errorMessage = error.userMessage
                    
                    // Add a fallback message to keep conversation flowing
                    let fallbackMessage = "I apologize, but I'm having trouble responding right now. Please try again in a moment."
                    _ = self.coreDataManager.addMessage(to: conversation, content: fallbackMessage, role: "ai")
                }
            }
        }
    }
    
    func clearCurrentConversation() {
        guard let conversation = currentConversation else { return }
        
        // Clear the summary first
        conversation.summary = nil
        
        // Get all messages associated with this conversation before deletion
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "conversation == %@", conversation)
        
        do {
            let messages = try coreDataManager.context.fetch(request)
            for message in messages {
                coreDataManager.context.delete(message)
            }
            
            // Save changes
            try coreDataManager.context.save()
        } catch {
            // Handle error silently
        }
    }
    
    func nukeAllData() {
        print("🔥 NUKING ALL DATA - Starting deletion process...")
        
        // First, let's count what we're about to delete
        let conversationRequest: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        let messageRequest: NSFetchRequest<Message> = Message.fetchRequest()
        
        do {
            let conversations = try coreDataManager.context.fetch(conversationRequest)
            let messages = try coreDataManager.context.fetch(messageRequest)
            
            print("🔥 Found \(conversations.count) conversations to delete")
            print("🔥 Found \(messages.count) messages to delete")
            
            // Log conversation details before deletion
            for (index, conversation) in conversations.enumerated() {
                if let date = conversation.date {
                    print("🔥 Conversation \(index + 1): Day \(conversation.dayNumber), Date: \(date), Messages: \(conversation.messages?.count ?? 0)")
                }
            }
            
            // Delete all conversations (this will cascade delete all messages due to Core Data relationships)
            for (index, conversation) in conversations.enumerated() {
                print("🔥 Deleting conversation \(index + 1)/\(conversations.count)")
                coreDataManager.context.delete(conversation)
            }
            
            print("🔥 Saving changes to Core Data...")
            // Save changes
            try coreDataManager.context.save()
            print("🔥 ✅ All conversations and messages deleted successfully!")
            
            // Reset current conversation
            currentConversation = nil
            print("🔥 Reset current conversation to nil")
            
            // Verify deletion
            let remainingConversations = try coreDataManager.context.fetch(conversationRequest)
            let remainingMessages = try coreDataManager.context.fetch(messageRequest)
            print("🔥 Verification: \(remainingConversations.count) conversations remaining")
            print("🔥 Verification: \(remainingMessages.count) messages remaining")
            
            // Set up a fresh conversation for today
            setupCurrentConversation()
            print("🔥 Created fresh conversation for today")
            print("🔥 ✅ NUKING COMPLETE!")
            
        } catch {
            print("🔥 ❌ ERROR during nuking: \(error)")
        }
    }
}

