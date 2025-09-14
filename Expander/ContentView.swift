//
//  ContentView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentConversation: Conversation?
    
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
                
                // Settings Icon (right)
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20) // Safe area padding for top
            
            // Chat Area 
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Day Header
                    Text("Day \(currentConversation?.dayNumber ?? 1)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    // Summary (show if conversation exists and has messages)
                    if let conversation = currentConversation, conversation.hasMessages {
                        Text(conversation.summary ?? "Great! This is the Expander app. We're building it step by step. What would you like to explore first?")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                    }
                    
                    // Display messages from Core Data
                    if let conversation = currentConversation {
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
                        }
                    }
                    
                    // Compact Breathwork Timer
                    BreathworkTimerView(isCompact: true)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            
            // Input Area
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
                
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 1)
                        )
                }
                .padding(.trailing, 32)
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onTapGesture {
            isTextFieldFocused = false
        }
        .onAppear {
            setupCurrentConversation()
        }
        }
    }
    
    // MARK: - Core Data Methods
    
    private func setupCurrentConversation() {
        let manager = CoreDataManager.shared
        let today = Date()
        
        currentConversation = manager.getOrCreateConversation(for: today)
        
        // Test: Add some initial messages if conversation is empty
        if let conversation = currentConversation, !conversation.hasMessages {
            // Add a welcome AI message
            manager.addMessage(to: conversation, content: "Hello! I'm your AI assistant. How can I help you today?", role: "ai")
            
            // Add a sample user message
            manager.addMessage(to: conversation, content: "Hi! I'd like to learn more about this app.", role: "user")
            
            // Add a response
            manager.addMessage(to: conversation, content: "Great! This is the Expander app. We're building it step by step. What would you like to explore first?", role: "ai")
            
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let conversation = currentConversation else { return }
        
        let manager = CoreDataManager.shared
        
        // Add user message
        manager.addMessage(to: conversation, content: messageText, role: "user")
        
        // Clear text field
        messageText = ""
        
        // Simulate AI response (for now, just echo back)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            manager.addMessage(to: conversation, content: "Thanks for your message: \"\(messageText)\"", role: "ai")
        }
        
    }
}

#Preview {
    ContentView()
}

// MARK: - Screen Views

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 9, day: 14))!
        let fiveWeeksSixDaysFromStart = calendar.date(byAdding: .day, value: 41, to: startDate)! // 6 weeks - 1 day
        return startDate...fiveWeeksSixDaysFromStart
    }
    
    private var calendarDays: [Date] {
        // Only show dates within our selected timeframe
        var days: [Date] = []
        var currentDate = dateRange.lowerBound
        
        while currentDate <= dateRange.upperBound {
            days.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Custom Header
                CustomHeaderView()
                
                VStack(spacing: 20) {
                    // Calendar Grid
                    CustomCalendarView(
                        selectedDate: $selectedDate,
                        dateRange: dateRange
                    )
                    .padding(.horizontal, 32) // Adjust calendar width here
                    .padding(.top, 24)
                    .padding(.bottom, 20) // Add more padding below calendar
                    
                    // Selected Day Conversation
                    DailyConversationView(date: selectedDate)
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

struct BreathworkView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            CustomHeaderView()
            
            // Full breathwork timer
            BreathworkTimerView(isCompact: false)
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

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var systemPrompt = "These are the days that lie ahead—the days to come, marching toward me like an inevitable tide. The days that will form my transformation window, a sacred span where I rewrite the scripts of pain and reclaim the flow of my being. They approach, relentless and full of promise, these days I must traverse, carrying me from the shadows of what has been into the light of what could be."
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            CustomHeaderView()
            
            VStack(alignment: .leading, spacing: 20) {
                // System prompt section
                VStack(alignment: .leading, spacing: 12) {
                    Text("System prompt")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    TextEditor(text: $systemPrompt)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 200)
                        .focused($isTextFieldFocused)
                        .lineSpacing(5) // Adjust line height here
                }
                
                Spacer()
                
                // Update button
                Button(action: {
                    // Update action placeholder
                }) {
                    Text("Update")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationBarHidden(true)
        .onTapGesture {
            isTextFieldFocused = false
        }
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

// MARK: - Custom Calendar View

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let dateRange: ClosedRange<Date>
    
    private let calendar = Calendar.current
    private let today = Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 15))! // Set today as Sept 15
    
    var body: some View {
        VStack(spacing: 16) {            
            // Day of week headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    DayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDate(date, inSameDayAs: today),
                        isInRange: dateRange.contains(date),
                        isFuture: date > today
                    ) {
                        if dateRange.contains(date) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
    }
    
    private var calendarDays: [Date] {
        // Only show dates within our selected timeframe
        var days: [Date] = []
        var currentDate = dateRange.lowerBound
        
        while currentDate <= dateRange.upperBound {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
}

struct DayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isInRange: Bool
    let isFuture: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .clipShape(Circle())
                .opacity(1.0) // All visible dates are at full opacity
        }
        .disabled(!isInRange)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color(red: 1.0, green: 0.23, blue: 0.19)
        } else if !isFuture && isInRange {
            return Color(red: 1.0, green: 0.23, blue: 0.19) // Red text for elapsed days
        } else if isFuture {
            return .gray // Gray out future dates
        } else if isInRange {
            return .white
        } else {
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color(red: 1.0, green: 0.23, blue: 0.19)
        } else if isToday {
            return Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.2)
        } else {
            return .clear // No background for elapsed days, just red text
        }
    }
}

// MARK: - Daily Conversation View

struct DailyConversationView: View {
    let date: Date
    
    private let calendar = Calendar.current
    private let today = Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 15))!
    
    private var isElapsed: Bool {
        date < today
    }
    
    private var isToday: Bool {
        calendar.isDate(date, inSameDayAs: today)
    }
    
    private var isFuture: Bool {
        date > today
    }
    
    private var dayNumber: Int {
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 14))!
        return calendar.dateComponents([.day], from: startDate, to: date).day! + 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day Header
            Text("Day \(dayNumber)")
                .font(.headline)
                .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                .padding(.horizontal, 20)
            
            if isElapsed {
                // Summary for elapsed days
                    Text("Great! This is the Expander app. We're building it step by step. What would you like to explore first?")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                
                // Conversation messages
                VStack(alignment: .leading, spacing: 16) {
                    // AI Message
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        Text("Hello! I'm your AI assistant. How can I help you today?")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                    }
                    
                    // User Message
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        Text("Hi! I'd like to learn more about this app.")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                    }
                    
                    // AI Message
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        Text("Great! This is the Expander app. We're building it step by step. What would you like to explore first?")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                    }
                }
            } else if isToday {
                // Today's conversation (in progress)
                Text("Today's conversation is in progress. Check back later for the complete summary.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            } else {
                // Placeholder for future days
                Text("Conversation will appear here once this day arrives.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Breathwork Timer Components

struct BreathworkTimerView: View {
    let isCompact: Bool
    @State private var currentPhase = "Ready"
    @State private var remainingSeconds = 0
    @State private var currentCycle = 0
    @State private var isActive = false
    @State private var timer: Timer?
    @State private var isCountingUp = false
    
    var body: some View {
        VStack(spacing: isCompact ? 24 : 64) {
            // Phase label
            Text(currentPhase)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
            
            // Circular timer
            ZStack {
                Circle()
                    .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 2)
                    .frame(width: isCompact ? 120 : 200, height: isCompact ? 120 : 200)
                
                Text("\(remainingSeconds)")
                    .font(.system(size: isCompact ? 50 : 100, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Progress dots (only in full version)
            if !isCompact {
                HStack(spacing: 12) {
                    ForEach(0..<10, id: \.self) { index in
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(index < currentCycle ? Color(red: 1.0, green: 0.23, blue: 0.19) : .gray)
                    }
                }.padding(.top, 24)
            }
            
            // Control buttons - always show both
            HStack(spacing: isCompact ? 20 : 32) {
                // Play/Pause button
                Button(action: {
                    toggleTimer()
                }) {
                    Image(systemName: isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                        .frame(width: isCompact ? 36 : 60, height: isCompact ? 36 : 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 2)
                        )
                }
                
                // Stop button
                Button(action: {
                    stopTimer()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: isCompact ? 16 : 20, weight: .medium))
                        .foregroundColor(isActive ? Color(red: 1.0, green: 0.23, blue: 0.19) : Color.gray.opacity(0.3))
                        .frame(width: isCompact ? 36 : 60, height: isCompact ? 36 : 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(isActive ? Color(red: 1.0, green: 0.23, blue: 0.19) : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                }
                .disabled(!isActive)
            }
            .padding(.top, isCompact ? 8 : 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black)
        .onDisappear {
            stopTimer()
        }
    }
    
    private func toggleTimer() {
        if isActive {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if isCountingUp {
                // Counting up (Breathe In: 1→4, Hold: 1→7)
                if currentPhase == "Breathe In" && remainingSeconds < 4 {
                    remainingSeconds += 1
                } else if currentPhase == "Hold" && remainingSeconds < 7 {
                    remainingSeconds += 1
                } else {
                    nextPhase()
                }
            } else {
                // Counting down (Breathe Out: 8→1)
                if remainingSeconds > 1 {
                    remainingSeconds -= 1
                } else {
                    nextPhase()
                }
            }
        }
    }
    
    private func pauseTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func stopTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
        currentPhase = "Ready"
        remainingSeconds = 0
        isCountingUp = false
    }
    
    private func nextPhase() {
        // Breathwork phase cycling with specific countdown patterns
        switch currentPhase {
        case "Ready":
            currentPhase = "Breathe In"
            remainingSeconds = 1
            isCountingUp = true
        case "Breathe In":
            currentPhase = "Hold"
            remainingSeconds = 1
            isCountingUp = true
        case "Hold":
            currentPhase = "Breathe Out"
            remainingSeconds = 8
            isCountingUp = false
        case "Breathe Out":
            currentPhase = "Breathe In"
            remainingSeconds = 1
            isCountingUp = true
        default:
            currentPhase = "Ready"
            remainingSeconds = 0
            isCountingUp = false
        }
    }
}

// MARK: - Custom Header View

struct CustomHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                    .font(.system(size: 18, weight: .medium))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24) // Fine control over top padding
        .padding(.bottom, 20) // Fine control over bottom padding
        .background(Color.black)
    }
}
