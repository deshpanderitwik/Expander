//
//  LLMService.swift
//  Expander
//
//  Created by Rit on 9/14/25.
//

import Foundation
import Network

/// Core service for LLM API communication
class LLMService: ObservableObject {
    static let shared = LLMService()
    
    // MARK: - Properties
    
    private let configManager = ConfigManager.shared
    private let urlSession: URLSession
    private let networkMonitor = NWPathMonitor()
    private var isNetworkAvailable = true
    
    // MARK: - Initialization
    
    private init() {
        print("🚀 Initializing LLMService...")
        
        // Configure URLSession with appropriate timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        
        self.urlSession = URLSession(configuration: config)
        print("✅ URLSession configured")
        
        // Start network monitoring
        startNetworkMonitoring()
        print("✅ Network monitoring started")
        
        // Validate configuration on initialization
        validateConfiguration()
        print("✅ Configuration validated")
        
        print("🎉 LLMService initialization complete")
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Configuration Validation
    
    private func validateConfiguration() {
        print("🔍 Validating configuration...")
        guard configManager.validateConfiguration() else {
            print("❌ Configuration validation failed")
            return
        }
        print("✅ Configuration validated successfully")
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    // MARK: - Core API Methods
    
    /// Sends a message to the LLM API with streaming response
    func sendMessage(
        messages: [Message],
        systemPrompt: String? = nil,
        completion: @escaping (Result<String, LLMError>) -> Void
    ) {
        sendMessageWithRetry(
            messages: messages,
            systemPrompt: systemPrompt,
            retryCount: 0,
            completion: completion
        )
    }
    
    /// Internal method with retry logic
    private func sendMessageWithRetry(
        messages: [Message],
        systemPrompt: String? = nil,
        retryCount: Int,
        completion: @escaping (Result<String, LLMError>) -> Void
    ) {
        // Validate network connectivity
        guard isNetworkAvailable else {
            completion(.failure(.noInternetConnection))
            return
        }
        
        // Validate configuration
        guard configManager.validateConfiguration() else {
            completion(.failure(.invalidConfiguration))
            return
        }
        
        do {
            // Build request directly from messages (non-streaming for breathwork integration)
            let request = try createChatRequestFromMessages(messages, systemPrompt: systemPrompt)
            
            // Validate request
            try request.validate()
            
            // Send request (non-streaming)
            sendRequest(request) { [weak self] result in
                switch result {
                case .success(let response):
                    completion(.success(response))
                case .failure(let error):
                    // Check if we should retry
                    if error.isRecoverable && retryCount < 3 {
                        let delay = self?.calculateRetryDelay(for: retryCount) ?? 1.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self?.sendMessageWithRetry(
                                messages: messages,
                                systemPrompt: systemPrompt,
                                retryCount: retryCount + 1,
                                completion: completion
                            )
                        }
                    } else {
                        completion(.failure(error))
                    }
                }
            }
            
        } catch let error as LLMError {
            completion(.failure(error))
        } catch {
            completion(.failure(.unknownError(error.localizedDescription)))
        }
    }
    
    /// Sends a single message to the LLM API
    func sendSingleMessage(
        content: String,
        systemPrompt: String? = nil,
        completion: @escaping (Result<String, LLMError>) -> Void
    ) {
        // Validate network connectivity
        guard isNetworkAvailable else {
            completion(.failure(.noInternetConnection))
            return
        }
        
        // Validate configuration
        guard configManager.validateConfiguration() else {
            completion(.failure(.invalidConfiguration))
            return
        }
        
        do {
            // Build request for single message (non-streaming)
            let request = try ChatRequest.forSingleMessage(
                content: content,
                systemPrompt: systemPrompt,
                model: configManager.xaiModel,
                stream: false
            )
            
            // Validate request
            try request.validate()
            
            // Send request (non-streaming)
            sendRequest(request, completion: completion)
            
        } catch let error as LLMError {
            completion(.failure(error))
        } catch {
            completion(.failure(.unknownError(error.localizedDescription)))
        }
    }
    
    // MARK: - Retry Logic
    
    /// Calculates exponential backoff delay for retries
    private func calculateRetryDelay(for retryCount: Int) -> TimeInterval {
        // Exponential backoff: 1s, 2s, 4s
        return pow(2.0, Double(retryCount))
    }
    
    // MARK: - Request Building
    
    private func createChatRequestFromMessages(_ messages: [Message], systemPrompt: String?) throws -> ChatRequest {
        // Convert Core Data messages to API messages
        var apiMessages = messages.map { APIMessage(from: $0) }
        
        // Add system prompt as first message if provided
        if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
            let systemMessage = APIMessage(role: "system", content: systemPrompt)
            apiMessages.insert(systemMessage, at: 0)
        }
        
        // Validate message count
        guard !apiMessages.isEmpty else {
            throw LLMError.invalidMessageFormat
        }
        
        // Validate total content length
        let totalLength = apiMessages.reduce(0) { $0 + $1.content.count }
        if totalLength > 100000 { // Rough token estimate
            throw LLMError.contextTooLong
        }
        
        return ChatRequest(
            model: configManager.xaiModel,
            messages: apiMessages,
            stream: false,
            maxTokens: 1000,
            temperature: 0.7,
            systemPrompt: nil // Remove systemPrompt from here since it's now in messages
        )
    }
    
    // MARK: - HTTP Request Handling
    
    private func sendRequest(
        _ request: ChatRequest,
        completion: @escaping (Result<String, LLMError>) -> Void
    ) {
        do {
            // Build URL
            let url = try buildAPIURL()
            
            // Create HTTP request
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(configManager.xaiAPIKey)", forHTTPHeaderField: "Authorization")
            
            // Encode request body
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(request)
            
            // Send request
            let task = urlSession.dataTask(with: urlRequest) { [weak self] data, response, error in
                self?.handleResponse(data: data, response: response, error: error, completion: completion)
            }
            
            task.resume()
            
        } catch {
            completion(.failure(.encodingError))
        }
    }
    
    private func buildAPIURL() throws -> URL {
        let baseURL = configManager.xaiBaseURL
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw LLMError.invalidConfiguration
        }
        return url
    }
    
    // MARK: - Response Handling
    
    private func handleResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<String, LLMError>) -> Void
    ) {
        // Handle network errors
        if let error = error {
            let llmError = mapNetworkError(error)
            DispatchQueue.main.async {
                completion(.failure(llmError))
            }
            return
        }
        
        // Handle HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            DispatchQueue.main.async {
                completion(.failure(.malformedResponse))
            }
            return
        }
        
        // Handle HTTP status codes
        if !(200...299).contains(httpResponse.statusCode) {
            let llmError = mapHTTPError(httpResponse.statusCode, data: data)
            DispatchQueue.main.async {
                completion(.failure(llmError))
            }
            return
        }
        
        // Handle response data
        guard let data = data else {
            DispatchQueue.main.async {
                completion(.failure(.emptyResponse))
            }
            return
        }
        
        // Process response
        processResponse(data: data, completion: completion)
    }
    
    private func processResponse(
        data: Data,
        completion: @escaping (Result<String, LLMError>) -> Void
    ) {
        do {
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            
            // Check for API errors
            if chatResponse.hasError {
                DispatchQueue.main.async {
                    completion(.failure(.serverError(500)))
                }
                return
            }
            
            // Extract content
            guard let content = chatResponse.content, !content.isEmpty else {
                DispatchQueue.main.async {
                    completion(.failure(.emptyResponse))
                }
                return
            }
            
            // Return successful response
            DispatchQueue.main.async {
                completion(.success(content))
            }
            
        } catch {
            DispatchQueue.main.async {
                completion(.failure(.decodingError))
            }
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapNetworkError(_ error: Error) -> LLMError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternetConnection
            case .timedOut:
                return .networkTimeout
            case .cannotConnectToHost, .cannotFindHost:
                return .connectionFailed
            default:
                return .connectionFailed
            }
        }
        return .unknownError(error.localizedDescription)
    }
    
    private func mapHTTPError(_ statusCode: Int, data: Data?) -> LLMError {
        switch statusCode {
        case 401:
            return .authenticationFailed
        case 429:
            return .rateLimitExceeded
        case 400:
            return .invalidRequest
        case 500...599:
            return .serverError(statusCode)
        default:
            return .serverError(statusCode)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Checks if the service is ready to make requests
    var isReady: Bool {
        return isNetworkAvailable && configManager.validateConfiguration()
    }
    
    /// Gets the current configuration status
    var configurationStatus: String {
        if !isNetworkAvailable {
            return "No internet connection"
        }
        
        if !configManager.validateConfiguration() {
            return "Invalid configuration"
        }
        
        return "Ready"
    }
    
    /// Gets the current model being used
    var currentModel: String {
        return configManager.xaiModel
    }
    
    /// Gets the current API base URL
    var currentBaseURL: String {
        return configManager.xaiBaseURL
    }
}
