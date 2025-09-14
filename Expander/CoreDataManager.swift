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
            return try context.fetch(request).first
        } catch {
            print("Fetch conversation error: \(error)")
            return nil
        }
    }
    
    func createConversation(for date: Date) -> Conversation {
        let conversation = Conversation(context: context)
        conversation.id = UUID()
        conversation.date = date
        conversation.timestamp = Date()
        conversation.status = "inProgress"
        
        // Calculate day number based on your app's start date
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 14))!
        let dayNumber = Calendar.current.dateComponents([.day], from: startDate, to: date).day! + 1
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
}
