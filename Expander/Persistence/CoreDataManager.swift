//
//  CoreDataManager.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import CoreData
import Foundation

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ExpanderModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Silent error handling
            }
        }
    }
    
    // MARK: - Conversation Methods
    
    func fetchConversation(for date: Date) -> Conversation? {
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        do {
            let result = try context.fetch(request).first
            return result
        } catch {
            return nil
        }
    }
    
    func createConversation(for date: Date) -> Conversation {
        let conversation = Conversation(context: context)
        conversation.id = UUID()
        
        // Store the date at start of day to ensure consistent matching
        let calendar = Calendar.current
        conversation.date = calendar.startOfDay(for: date)
        conversation.timestamp = Date()
        conversation.status = "inProgress"
        
        // Calculate day number based on October 1st, 2025 (fixed app start date)
        let startDate = calendar.startOfDay(for: calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!)
        let dayNumber = calendar.dateComponents([.day], from: startDate, to: calendar.startOfDay(for: date)).day!
        conversation.dayNumber = Int16(dayNumber)
        save()
        return conversation
    }
    
    func addMessage(to conversation: Conversation, content: String, role: String) -> Message {
        let message = Message(context: context)
        message.id = UUID()
        message.content = content
        message.role = role
        message.timestamp = Date()
        message.conversation = conversation
        
        // Set order based on existing messages
        let existingMessages = conversation.messages?.allObjects as? [Message] ?? []
        message.order = Int16(existingMessages.count)
        
        save()
        return message
    }
    
    func fetchAllConversations() -> [Conversation] {
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conversation.date, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    /// Get the earliest conversation date (app start date)
    func getEarliestConversationDate() -> Date? {
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conversation.date, ascending: true)]
        request.fetchLimit = 1
        
        do {
            let conversations = try context.fetch(request)
            let earliestDate = conversations.first?.date
            
            
            return earliestDate
        } catch {
            print("Error fetching earliest conversation: \(error)")
            return nil
        }
    }
    
    func getOrCreateConversation(for date: Date) -> Conversation {
        if let existingConversation = fetchConversation(for: date) {
            return existingConversation
        } else {
            return createConversation(for: date)
        }
    }
    
    // MARK: - Utility Methods
    
    func deleteConversation(_ conversation: Conversation) {
        context.delete(conversation)
        save()
    }
    
    func deleteMessage(_ message: Message) {
        context.delete(message)
        save()
    }
    
    /// Fixes day numbers for existing conversations based on current date logic
    func fixExistingDayNumbers() {
        // Always recalculate day numbers when this method is called
        
        let conversations = fetchAllConversations()
        
        let calendar = Calendar.current
        var needsFix = false
        
        for conversation in conversations {
            guard let conversationDate = conversation.date else { 
                continue 
            }
            
            // Calculate correct day number based on October 1st, 2025 (fixed app start date)
            let startDate = calendar.startOfDay(for: calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!)
            let correctDayNumber = calendar.dateComponents([.day], from: startDate, to: calendar.startOfDay(for: conversationDate)).day!
            
            
            // Update if different
            if conversation.dayNumber != Int16(correctDayNumber) {
                conversation.dayNumber = Int16(correctDayNumber)
                needsFix = true
            }
        }
        
        if needsFix {
            save()
        }
        
        // Day numbers have been recalculated
    }
    
    // MARK: - Cleanup Methods
    
    /// Clears all placeholder conversations and messages
    func clearAllData() {
        let conversations = fetchAllConversations()
        for conversation in conversations {
            deleteConversation(conversation)
        }
    }
    
    /// Clears only conversations with placeholder content
    func clearPlaceholderConversations() {
        let conversations = fetchAllConversations()
        
        for conversation in conversations {
            let messages = conversation.sortedMessages
            let hasPlaceholderContent = messages.contains { message in
                let content = message.safeContent.lowercased()
                return content.contains("great! this is the expander app") ||
                       content.contains("hello! i'm your ai assistant") ||
                       content.contains("hi! i'd like to learn more about this app") ||
                       content.contains("thanks for your message")
            }
            
            if hasPlaceholderContent {
                deleteConversation(conversation)
            }
        }
    }
}
