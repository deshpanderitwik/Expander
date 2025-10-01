//
//  ChatView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI
import CoreData

struct ChatView: View {
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var shouldScrollToLatest = false
    @Binding var systemPrompt: String
    
    var body: some View {
        // Chat Area with gradient overlay
        ZStack(alignment: .top) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Day Header
                        Text("Day \(chatViewModel.currentConversation?.dayNumber ?? 0)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        // Display messages from Core Data
                        if let conversation = chatViewModel.currentConversation {
                            ForEach(conversation.sortedMessages, id: \.id) { message in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.displayRole)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 20)
                                    
                                    Text(message.safeContent)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                }
                                .id(message.id)
                            }
                            
                            // Clear Current Conversation Button (for testing)
                            if !conversation.sortedMessages.isEmpty {
                                Button(action: {
                                    chatViewModel.clearCurrentConversation()
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("Clear Conversation")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            }
                            
                            // Show compact breathwork timer for AI response or daily breathwork
                            if chatViewModel.isLoading {
                                CompactBreathworkTimerView()
                                    .id("breathwork-timer")
                            } else if false { // Daily breathwork removed
                                CompactBreathworkTimerView()
                                    .id("daily-breathwork-timer")
                            }
                            
                            // Show error message if any
                            if let errorMessage = chatViewModel.errorMessage {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Error")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 20)
                                    
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Compact Breathwork Timer - removed for clean chat experience
                        // BreathworkTimerView(isCompact: true)
                        //     .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
                .onTapGesture {
                    isTextFieldFocused = false
                    // Dismiss error message when tapping
                    if chatViewModel.errorMessage != nil {
                        chatViewModel.errorMessage = nil
                    }
                }
                .onChange(of: chatViewModel.isLoading) { _, newValue in
                    if newValue {
                        // Scroll to breathwork timer when loading starts
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("breathwork-timer", anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: shouldScrollToLatest) { _, newValue in
                    if newValue {
                        if let conversation = chatViewModel.currentConversation,
                           let lastMessage = conversation.sortedMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .top)
                        }
                        shouldScrollToLatest = false
                    }
                }
            }
            
            // Top gradient overlay that sits on top of scrollable content
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.4),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)
                .allowsHitTesting(false)
                
                Spacer()
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
            // Dismiss error message when tapping
            if chatViewModel.errorMessage != nil {
                chatViewModel.errorMessage = nil
            }
        }
        
        // Main Chat Footer with Gradient
        FooterWithGradient(gradientHeight: 36, gradientOffset: -36) {
            HStack(alignment: .center, spacing: 0) {
                TextField("Type your message...", text: $messageText, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        // Prevent tap from propagating to parent view
                        // This allows the text field to be tapped for editing without dismissing focus
                    }
                
                Button(action: {
                    sendMessage()
                }) {
                    if chatViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 1)
                            )
                    }
                }
                .disabled(chatViewModel.isLoading)
                .padding(.trailing, 32)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .onTapGesture {
            // Only dismiss keyboard if not tapping on the text field or send button
            isTextFieldFocused = false
        }
        .onAppear {
            // Fix day numbers for existing conversations based on new start date
            CoreDataManager.shared.fixExistingDayNumbers()
            
            chatViewModel.setupCurrentConversation()
            
            // Scroll to latest message immediately
            if let conversation = chatViewModel.currentConversation,
               let lastMessage = conversation.sortedMessages.last {
                shouldScrollToLatest = true
            }
            
            // Safety mechanism: Reset loading state if it gets stuck
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if chatViewModel.isLoading {
                    chatViewModel.isLoading = false
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let textToSend = messageText
        messageText = "" // Clear text field immediately
        
        chatViewModel.sendMessage(textToSend, systemPrompt: systemPrompt.isEmpty ? nil : systemPrompt)
    }
}

#Preview {
    ChatView(systemPrompt: .constant(""))
        .environmentObject(ChatViewModel())
}