//
//  CalendarView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Custom Header
                CustomHeaderView()
                
                VStack(spacing: 20) {
                    // Calendar Grid
                    CustomCalendarView(viewModel: viewModel)
                        .padding(.horizontal, 32) // Adjust calendar width here
                        .padding(.top, 24)
                        .padding(.bottom, 20) // Add more padding below calendar
                    
                    // Selected Day Conversation
                    DailyConversationView(date: viewModel.selectedDate)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.startLocation.x < 50 && value.translation.width > 100 {
                        dismiss()
                    }
                }
        )
    }
}
