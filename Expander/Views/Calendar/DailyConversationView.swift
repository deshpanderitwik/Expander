//
//  DailyConversationView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI
import CoreData

struct DailyConversationView: View {
    let date: Date
    @StateObject private var viewModel: DailyConversationViewModel
    
    init(date: Date) {
        self.date = date
        self._viewModel = StateObject(wrappedValue: DailyConversationViewModel(date: date))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day Header
            Text("Day \(viewModel.dayNumber)")
                .font(.headline)
                .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                .padding(.horizontal, 20)
            
            // Generate Summary Button (only show for elapsed days with conversations but no summary)
            if viewModel.isElapsed, 
               viewModel.hasMessages, 
               !viewModel.hasSummary {
                VStack(spacing: 8) {
                    Button(action: {
                        viewModel.generateSummary()
                    }) {
                        HStack {
                            if DailyOrchestrator.shared.isCurrentlyProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            Text(DailyOrchestrator.shared.isCurrentlyProcessing ? "Generating..." : "Generate Summary")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .disabled(DailyOrchestrator.shared.isCurrentlyProcessing)
                    .opacity(DailyOrchestrator.shared.isCurrentlyProcessing ? 0.6 : 1.0)
                    
                    if DailyOrchestrator.shared.isCurrentlyProcessing {
                        Text("This may take up to 2 minutes...")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                    }
                }
            }
            
            if viewModel.isElapsed {
                // Summary for elapsed days - will show actual conversation summary when available
                if let conversation = viewModel.conversation,
                   let summary = conversation.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(summary)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        // Clear Summary Button
                        Button(action: {
                            viewModel.clearSummary()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Clear Summary")
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
                    }
                } else if viewModel.hasMessages {
                    Text("Summary will be generated at the end of the day.")
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                } else {
                    Text("No conversation for this day.")
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                }
                
                // Show actual conversation messages if they exist
                if viewModel.hasMessages {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.sortedMessages, id: \.id) { message in
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
                        }
                    }
                }
            } else if viewModel.isToday {
                // Today's conversation (in progress)
                if viewModel.hasMessages {
                    Text("Today's conversation is in progress.")
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    // Show messages from today's conversation
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.sortedMessages, id: \.id) { message in
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
                        }
                    }
                } else {
                    Text("Today's conversation will appear here once you start chatting.")
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                }
            } else {
                // Placeholder for future days
                Text("Conversation will appear here once this day arrives.")
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }
}
