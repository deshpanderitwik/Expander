//
//  ContentView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var systemPrompt = ""
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                // Navigation HStack
                HStack(spacing: 20) {
                    // Calendar Icon (left)
                    NavigationLink(destination: CalendarView()) {
                        Image(systemName: "calendar")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                            .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                    
                    // Warning Icon (middle)
                    NavigationLink(destination: BreathworkView()) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                            .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                    
                    // Nuke All Data Button
                    Button(action: {
                        chatViewModel.nukeAllData()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.red)
                            .frame(width: 32, height: 32)
                    }
                    .disabled(chatViewModel.isLoading)
                    .opacity(chatViewModel.isLoading ? 0.6 : 1.0)
                    
                    Spacer()
                    
                    // Settings Icon (right)
                    NavigationLink(destination: SettingsView(systemPrompt: $systemPrompt)) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20) // Safe area padding for top
                
                // Chat Area
                ChatView(systemPrompt: $systemPrompt)
                    .environmentObject(chatViewModel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .onAppear {
                // Debug: Check what conversations exist
                let _ = CoreDataManager.shared.fetchAllConversations()
                
                // Fix day numbers for existing conversations based on new start date
                CoreDataManager.shared.fixExistingDayNumbers()
            }
        }
    }
}

#Preview {
    ContentView()
}

