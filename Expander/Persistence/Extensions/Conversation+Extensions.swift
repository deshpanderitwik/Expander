//
//  Conversation+Extensions.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import Foundation
import CoreData

extension Conversation {
    var isToday: Bool {
        Calendar.current.isDateInToday(date ?? Date())
    }
    
    var isFuture: Bool {
        guard let date = date else { return false }
        return date > Date()
    }
    
    var isElapsed: Bool {
        guard let date = date else { return false }
        return date < Date()
    }
    
    var sortedMessages: [Message] {
        let messages = messages?.allObjects as? [Message] ?? []
        return messages.sorted { $0.order < $1.order }
    }
    
    var userMessages: [Message] {
        sortedMessages.filter { $0.role == "user" }
    }
    
    var aiMessages: [Message] {
        sortedMessages.filter { $0.role == "ai" }
    }
    
    var systemMessages: [Message] {
        sortedMessages.filter { $0.role == "system" }
    }
    
    var hasMessages: Bool {
        (messages?.count ?? 0) > 0
    }
    
    var lastMessage: Message? {
        sortedMessages.last
    }
    
    var firstMessage: Message? {
        sortedMessages.first
    }
    
    // Computed property for display status
    var displayStatus: String {
        switch status {
        case "completed":
            return "Completed"
        case "inProgress":
            return "In Progress"
        case "future":
            return "Future"
        default:
            return "Unknown"
        }
    }
    
    // Helper to check if conversation is ready for summary
    var isReadyForSummary: Bool {
        isElapsed && hasMessages && status != "completed"
    }
}
