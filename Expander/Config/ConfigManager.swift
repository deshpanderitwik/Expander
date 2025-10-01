//
//  ConfigManager.swift
//  Expander
//
//  Created by Rit on 9/14/25.
//

import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    private let config: [String: Any]
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Config.plist not found in bundle. Please ensure Config.plist exists and is added to the target.")
        }
        self.config = config
    }
    
    var xaiAPIKey: String {
        guard let key = config["XAI_API_KEY"] as? String, !key.isEmpty else {
            fatalError("XAI_API_KEY not found in Config.plist")
        }
        
        // Validate that the key has been set (not the placeholder)
        if key == "YOUR_API_KEY_HERE" {
            fatalError("Please set your actual XAI API key in Config.plist. Replace 'YOUR_API_KEY_HERE' with your real API key.")
        }
        
        return key
    }
    
    var xaiBaseURL: String {
        guard let url = config["XAI_BASE_URL"] as? String, !url.isEmpty else {
            fatalError("XAI_BASE_URL not found in Config.plist")
        }
        return url
    }
    
    var xaiModel: String {
        guard let model = config["XAI_MODEL"] as? String, !model.isEmpty else {
            fatalError("XAI_MODEL not found in Config.plist")
        }
        return model
    }
    
    // Helper method to validate configuration
    func validateConfiguration() -> Bool {
        // Check if all required configuration values are available
        let apiKey = config["XAI_API_KEY"] as? String
        let baseURL = config["XAI_BASE_URL"] as? String
        let model = config["XAI_MODEL"] as? String
        
        return apiKey != nil && !apiKey!.isEmpty && 
               baseURL != nil && !baseURL!.isEmpty && 
               model != nil && !model!.isEmpty &&
               apiKey != "YOUR_API_KEY_HERE"
    }
}
