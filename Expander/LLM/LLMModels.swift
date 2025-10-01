//
//  LLMModels.swift
//  Expander
//
//  Created by Rit on 9/14/25.
//

import Foundation
import CoreData

// MARK: - API Request Models

/// Represents a message in the API request format
struct APIMessage: Codable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

/// Request structure for XAI Chat API
struct ChatRequest: Codable {
    let model: String
    let messages: [APIMessage]
    let stream: Bool
    let maxTokens: Int?
    let temperature: Double?
    let systemPrompt: String?
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case stream
        case maxTokens = "max_tokens"
        case temperature
        case systemPrompt = "system_prompt"
    }
    
    init(
        model: String,
        messages: [APIMessage],
        stream: Bool = true,
        maxTokens: Int? = nil,
        temperature: Double? = 0.7,
        systemPrompt: String? = nil
    ) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.systemPrompt = systemPrompt
    }
}

// MARK: - API Response Models

/// Response structure for XAI Chat API
struct ChatResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [ChatChoice]?
    let usage: UsageInfo?
    let error: APIError?
}

struct ChatChoice: Codable {
    let index: Int?
    let message: APIMessage?
    let delta: APIMessage?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case delta
        case finishReason = "finish_reason"
    }
}

struct UsageInfo: Codable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct APIError: Codable {
    let message: String
    let type: String?
    let code: String?
}

// MARK: - Streaming Response Models

/// Represents a streaming response chunk
struct StreamingResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [ChatChoice]?
    let error: APIError?
}

// MARK: - Core Data Integration

extension APIMessage {
    /// Creates an APIMessage from a Core Data Message
    init(from message: Message) {
        // Convert Core Data role to API role
        let coreDataRole = message.role ?? "user"
        let apiRole: String
        
        switch coreDataRole {
        case "ai":
            apiRole = "assistant"  // Convert "ai" to "assistant" for API
        case "user", "system", "assistant":
            apiRole = coreDataRole  // Keep as-is
        default:
            apiRole = "user"  // Default fallback
        }
        
        self.role = apiRole
        self.content = message.content ?? ""
    }
    
    /// Creates an APIMessage with specified role and content
    init(role: MessageRole, content: String) {
        self.role = role.rawValue
        self.content = content
    }
}

/// Enum for message roles to ensure type safety
enum MessageRole: String, CaseIterable {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
    
    /// Converts to the role format expected by XAI API
    var apiRole: String {
        switch self {
        case .system:
            return "system"
        case .user:
            return "user"
        case .assistant:
            return "assistant"
        }
    }
}

// MARK: - Request Building Utilities

extension ChatRequest {
    /// Creates a ChatRequest from Core Data conversation
    static func from(
        conversation: Conversation,
        systemPrompt: String? = nil,
        model: String,
        stream: Bool = false,
        maxTokens: Int? = nil,
        temperature: Double? = 0.7
    ) throws -> ChatRequest {
        let messages = conversation.sortedMessages.map { APIMessage(from: $0) }
        
        // Validate message count
        guard !messages.isEmpty else {
            throw LLMError.invalidMessageFormat
        }
        
        // Validate total content length
        let totalLength = messages.reduce(0) { $0 + $1.content.count }
        if totalLength > 100000 { // Rough token estimate
            throw LLMError.contextTooLong
        }
        
        // Validate system prompt length
        if let systemPrompt = systemPrompt, systemPrompt.count > 10000 {
            throw LLMError.systemPromptTooLong
        }
        
        return ChatRequest(
            model: model,
            messages: messages,
            stream: stream,
            maxTokens: maxTokens,
            temperature: temperature,
            systemPrompt: systemPrompt
        )
    }
    
    /// Creates a ChatRequest for a single message
    static func forSingleMessage(
        content: String,
        systemPrompt: String? = nil,
        model: String,
        stream: Bool = false,
        maxTokens: Int? = nil,
        temperature: Double? = 0.7
    ) throws -> ChatRequest {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.invalidMessageFormat
        }
        
        let userMessage = APIMessage(role: .user, content: content)
        
        return ChatRequest(
            model: model,
            messages: [userMessage],
            stream: stream,
            maxTokens: maxTokens,
            temperature: temperature,
            systemPrompt: systemPrompt
        )
    }
}

// MARK: - Response Processing Utilities

extension ChatResponse {
    /// Extracts the content from the response
    var content: String? {
        return choices?.first?.message?.content ?? choices?.first?.delta?.content
    }
    
    /// Checks if the response contains an error
    var hasError: Bool {
        return error != nil
    }
    
    /// Gets the error message if present
    var errorMessage: String? {
        return error?.message
    }
    
    /// Checks if this is a streaming response
    var isStreaming: Bool {
        return choices?.first?.delta != nil
    }
    
    /// Checks if the stream is complete
    var isComplete: Bool {
        return choices?.first?.finishReason != nil
    }
}

extension StreamingResponse {
    /// Extracts the content delta from the streaming response
    var contentDelta: String? {
        return choices?.first?.delta?.content
    }
    
    /// Checks if the streaming response contains an error
    var hasError: Bool {
        return error != nil
    }
    
    /// Gets the error message if present
    var errorMessage: String? {
        return error?.message
    }
    
    /// Checks if the stream is complete
    var isComplete: Bool {
        return choices?.first?.finishReason != nil
    }
}

// MARK: - Validation Utilities

extension ChatRequest {
    /// Validates the request before sending
    func validate() throws {
        // Check model
        guard !model.isEmpty else {
            throw LLMError.invalidRequest
        }
        
        // Check messages
        guard !messages.isEmpty else {
            throw LLMError.invalidMessageFormat
        }
        
        // Check each message
        for message in messages {
            guard !message.content.isEmpty else {
                throw LLMError.invalidMessageFormat
            }
            
            guard MessageRole.allCases.contains(where: { $0.rawValue == message.role }) else {
                throw LLMError.invalidMessageFormat
            }
        }
        
        // Check system prompt length
        if let systemPrompt = systemPrompt, systemPrompt.count > 10000 {
            throw LLMError.systemPromptTooLong
        }
        
        // Check total content length
        let totalLength = messages.reduce(0) { $0 + $1.content.count }
        if totalLength > 100000 {
            throw LLMError.contextTooLong
        }
    }
}
