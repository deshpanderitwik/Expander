//
//  Message+Extensions.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import Foundation
import CoreData

extension Message {
    var isUserMessage: Bool {
        role == "user"
    }
    
    var isAIMessage: Bool {
        role == "ai"
    }
    
    var isSystemMessage: Bool {
        role == "system"
    }
    
    // Computed property for display role
    var displayRole: String {
        switch role {
        case "user":
            return "You"
        case "ai":
            return "AI"
        case "system":
            return "System"
        default:
            return "Unknown"
        }
    }
    
    // Helper to format timestamp for display
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: timestamp ?? Date())
    }
    
    // Helper to get message content with fallback
    var safeContent: String {
        content ?? ""
    }
    
    // Helper to check if message is empty
    var isEmpty: Bool {
        safeContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
