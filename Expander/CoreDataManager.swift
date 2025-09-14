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
                print("Save error: \(error)")
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
            print("🔍 Fetching conversation for \(date) (startOfDay: \(startOfDay), endOfDay: \(endOfDay)): \(result != nil ? "Found" : "Not found")")
            if let found = result {
                print("   Found conversation with date: \(found.date ?? Date())")
                print("   Messages count: \(found.messages?.count ?? 0)")
                print("   hasMessages: \(found.hasMessages)")
                if let messages = found.messages?.allObjects as? [Message] {
                    print("   Message roles: \(messages.map { $0.role ?? "nil" })")
                }
            }
            return result
        } catch {
            print("Fetch conversation error: \(error)")
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
        
        // Calculate day number based on your app's start date
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 9, day: 14))!
        let dayNumber = calendar.dateComponents([.day], from: startDate, to: date).day! + 1
        conversation.dayNumber = Int16(dayNumber)
        
        print("📝 Created new conversation for \(date) -> stored as \(conversation.date!) (Day \(dayNumber))")
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
        
        print("💬 Added message to conversation (date: \(conversation.date ?? Date())): role=\(role), order=\(message.order), content length=\(content.count)")
        
        save()
        return message
    }
    
    func fetchAllConversations() -> [Conversation] {
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conversation.date, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch conversations error: \(error)")
            return []
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
    
    // MARK: - Mock Data Methods
    
    /// Creates mock conversations for testing calendar functionality
    func createMockConversations() {
        let calendar = Calendar.current
        
        // Day 1: September 14, 2025
        let day1Date = calendar.date(from: DateComponents(year: 2025, month: 9, day: 14))!
        print("📅 Creating mock conversation for Day 1: \(day1Date)")
        let day1Conversation = createConversation(for: day1Date)
        day1Conversation.summary = "Explored the concept of mindful creativity and how daily reflection can enhance artistic expression. Discussed the importance of setting intentions before creative work."
        
        let day1Messages = [
            ("I've been feeling stuck in my writing lately. How can I approach creativity more mindfully?", "user"),
            ("Creative blocks often arise from pressure and expectation. Try beginning each writing session with a simple breathing exercise—four counts in, seven counts hold, eight counts out. This creates space for your authentic voice to emerge. What if you wrote without any goal in mind, just to explore what wants to be said?", "ai"),
            ("That's beautiful. I love the idea of writing as exploration rather than production.", "user"),
            ("Exactly. When we release the need to produce something 'good,' we often discover our most genuine expressions. Consider keeping a morning journal where you write three pages of stream-of-consciousness before any 'real' work. This practice clears mental clutter and often reveals unexpected insights.", "ai")
        ]
        
        for (content, role) in day1Messages {
            _ = addMessage(to: day1Conversation, content: content, role: role)
        }
        
        // Day 2: September 15, 2025 (Today)
        let day2Date = calendar.date(from: DateComponents(year: 2025, month: 9, day: 15))!
        print("📅 Creating mock conversation for Day 2: \(day2Date)")
        let day2Conversation = createConversation(for: day2Date)
        
        let day2Messages = [
            ("I tried the breathing exercise before writing today. It felt different.", "user"),
            ("Tell me about the difference you noticed. What shifted in your experience?", "ai")
        ]
        
        for (content, role) in day2Messages {
            _ = addMessage(to: day2Conversation, content: content, role: role)
        }
        
        // Note: Day 3 (Sept 16) is a future day, so no conversation should be created
        
        // Final save to ensure all data is persisted
        save()
        
        print("📚 Created mock conversations for testing calendar view")
        
        // Debug: List all conversations to verify they were created
        let allConversations = fetchAllConversations()
        print("📋 All conversations in database:")
        for conversation in allConversations {
            print("   - Date: \(conversation.date ?? Date()), Messages: \(conversation.messages?.count ?? 0), Summary: \(conversation.summary?.isEmpty == false ? "Yes" : "No")")
            if let messages = conversation.messages?.allObjects as? [Message] {
                print("     Message roles: \(messages.map { $0.role ?? "nil" })")
            }
        }
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
