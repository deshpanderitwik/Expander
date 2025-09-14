//
//  LLMError.swift
//  Expander
//
//  Created by Rit on 9/14/25.
//

import Foundation

/// Comprehensive error handling for LLM API operations
enum LLMError: Error, LocalizedError {
    // MARK: - Configuration Errors
    case missingAPIKey
    case invalidAPIKey
    case missingBaseURL
    case invalidConfiguration
    
    // MARK: - Network Errors
    case noInternetConnection
    case networkTimeout
    case serverUnavailable
    case connectionFailed
    
    // MARK: - API Errors
    case rateLimitExceeded
    case authenticationFailed
    case invalidRequest
    case serverError(Int)
    case malformedResponse
    
    // MARK: - Content Errors
    case emptyResponse
    case invalidMessageFormat
    case contextTooLong
    case systemPromptTooLong
    
    // MARK: - Internal Errors
    case unknownError(String)
    case decodingError
    case encodingError
    
    var errorDescription: String? {
        switch self {
        // Configuration Errors
        case .missingAPIKey:
            return "API configuration is missing. Please check your settings."
        case .invalidAPIKey:
            return "API key is invalid. Please verify your configuration."
        case .missingBaseURL:
            return "API endpoint configuration is missing."
        case .invalidConfiguration:
            return "Invalid configuration detected. Please check your settings."
            
        // Network Errors
        case .noInternetConnection:
            return "No internet connection available. Please check your network."
        case .networkTimeout:
            return "Request timed out. Please try again."
        case .serverUnavailable:
            return "Service is temporarily unavailable. Please try again later."
        case .connectionFailed:
            return "Failed to connect to the service. Please check your connection."
            
        // API Errors
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment before trying again."
        case .authenticationFailed:
            return "Authentication failed. Please check your API credentials."
        case .invalidRequest:
            return "Invalid request format. Please try again."
        case .serverError(let code):
            return "Server error occurred (Code: \(code)). Please try again later."
        case .malformedResponse:
            return "Received invalid response from the service."
            
        // Content Errors
        case .emptyResponse:
            return "No response received from the AI service."
        case .invalidMessageFormat:
            return "Message format is invalid. Please try again."
        case .contextTooLong:
            return "Conversation is too long. Please start a new conversation."
        case .systemPromptTooLong:
            return "System prompt is too long. Please shorten it."
            
        // Internal Errors
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        case .decodingError:
            return "Failed to process the response. Please try again."
        case .encodingError:
            return "Failed to prepare the request. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingAPIKey, .invalidAPIKey, .missingBaseURL, .invalidConfiguration:
            return "Please check your API configuration in the app settings."
        case .noInternetConnection, .networkTimeout, .connectionFailed:
            return "Check your internet connection and try again."
        case .rateLimitExceeded:
            return "Wait a few moments before sending another message."
        case .serverUnavailable, .serverError:
            return "The service is temporarily unavailable. Please try again in a few minutes."
        case .contextTooLong:
            return "Consider starting a new conversation to continue."
        case .systemPromptTooLong:
            return "Shorten your system prompt to continue."
        default:
            return "Please try again. If the problem persists, restart the app."
        }
    }
    
    /// Determines if the error is recoverable (user can retry)
    var isRecoverable: Bool {
        switch self {
        case .missingAPIKey, .invalidAPIKey, .missingBaseURL, .invalidConfiguration:
            return false // Requires configuration change
        case .noInternetConnection, .networkTimeout, .connectionFailed, .rateLimitExceeded:
            return true // Temporary issues
        case .serverUnavailable, .serverError:
            return true // Server issues are usually temporary
        case .contextTooLong, .systemPromptTooLong:
            return false // Requires user action
        case .emptyResponse, .malformedResponse, .decodingError, .encodingError:
            return true // Technical issues that might resolve
        case .invalidRequest, .invalidMessageFormat:
            return true // Might work with different input
        case .authenticationFailed:
            return false // Requires configuration fix
        case .unknownError:
            return true // Unknown errors might be temporary
        }
    }
    
    /// Determines if the error should be shown to the user
    var shouldShowToUser: Bool {
        switch self {
        case .missingAPIKey, .invalidAPIKey, .missingBaseURL, .invalidConfiguration:
            return true // User needs to fix configuration
        case .noInternetConnection, .networkTimeout, .connectionFailed:
            return true // User needs to check connection
        case .rateLimitExceeded:
            return true // User needs to wait
        case .serverUnavailable, .serverError:
            return true // User needs to know service is down
        case .contextTooLong, .systemPromptTooLong:
            return true // User needs to take action
        case .emptyResponse, .malformedResponse:
            return true // User should know something went wrong
        case .invalidRequest, .invalidMessageFormat:
            return true // User should try again
        case .authenticationFailed:
            return true // User needs to fix credentials
        case .decodingError, .encodingError, .unknownError:
            return false // Technical errors, show generic message
        }
    }
}

/// Helper for creating user-friendly error messages
extension LLMError {
    /// Returns a user-friendly error message suitable for display in UI
    var userMessage: String {
        if shouldShowToUser {
            return errorDescription ?? "An error occurred"
        } else {
            return "Something went wrong. Please try again."
        }
    }
    
    /// Returns a detailed error message for debugging (not shown to users)
    var debugMessage: String {
        switch self {
        case .serverError(let code):
            return "Server error: HTTP \(code)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        default:
            return "\(self): \(errorDescription ?? "No description")"
        }
    }
}
