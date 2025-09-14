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
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var systemPrompt = "You are a masterful literary writer with a sharp eye for emotional nuance and sensory texture. Your prose is cinematic, immersive, and rhythmically alive—recalling the emotional depth of Ishiguro, the lushness of García Márquez, and the sculpted clarity of Tartt. You render the ordinary with mythic weight, and the mythic with human intimacy. When given a scene or character, you write with layered sensuality: light, texture, scent, sound, spatial rhythm. Beneath the surface, let a current of emotion—nostalgia, longing, dread, joy—move subtly through tone and silence. Reveal character through what they don't say: gesture, stillness, a broken pattern. The setting breathes too—alive with memory and intent, never just background. Sentence length shifts with feeling: some clipped and quiet, others long and tidal. Let the prose feel composed but never static. Each paragraph should stand on its own, yet draw the reader deeper into a world that pulses with presence and hidden feeling."
    
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
                NavigationLink(destination: SettingsView(systemPrompt: $systemPrompt)) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20) // Safe area padding for top
            
            // Chat Area with gradient overlay
            ZStack(alignment: .top) {
                ScrollViewReader { proxy in
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
                        if let summary = conversation.summary, !summary.isEmpty {
                            Text(summary)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                        }
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
                        
                        // Show compact breathwork timer for AI response
                        if isLoading {
                            CompactBreathworkTimerView()
                                .id("breathwork-timer")
                        }
                        
                        // Show error message if any
                        if let errorMessage = errorMessage {
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
            .onChange(of: isLoading) { _, newValue in
                if newValue {
                    // Scroll to breathwork timer when loading starts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("breathwork-timer", anchor: .bottom)
                        }
                    }
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
                    
                    Button(action: {
                        print("🔘 Send button tapped, isLoading: \(isLoading)")
                        sendMessage()
                    }) {
                        if isLoading {
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
                    .disabled(isLoading)
                    .padding(.trailing, 32)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onTapGesture {
            isTextFieldFocused = false
            // Dismiss error message when tapping
            if errorMessage != nil {
                errorMessage = nil
            }
        }
        .onAppear {
            setupCurrentConversation()
            
            // Safety mechanism: Reset loading state if it gets stuck
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if isLoading {
                    print("⚠️ Loading state was stuck, resetting...")
                    isLoading = false
                }
            }
        }
        }
    }
    
    // MARK: - Core Data Methods
        
    private func setupCurrentConversation() {
        let manager = CoreDataManager.shared
        let today = Date()
        
        // Use start of day to ensure consistent date matching
        let calendar = Calendar.current
        let normalizedToday = calendar.startOfDay(for: today)
        print("📅 Main view: Getting conversation for normalized date: \(normalizedToday)")
        currentConversation = manager.getOrCreateConversation(for: normalizedToday)
        print("🏠 Main view: Current conversation set - hasMessages: \(currentConversation?.hasMessages == true), message count: \(currentConversation?.messages?.count ?? 0)")
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let conversation = currentConversation else { return }
        
        let manager = CoreDataManager.shared
        
        // Add user message
        _ = manager.addMessage(to: conversation, content: messageText, role: "user")
        print("💬 Main view: Added user message to conversation - total messages: \(conversation.messages?.count ?? 0)")
        
        // Clear text field and error message
        messageText = ""
        errorMessage = nil
        
        // Set loading state
        isLoading = true
        print("🔄 Set isLoading to true")
        
        // Debug: Check if LLMService is ready
        print("LLMService is ready: \(LLMService.shared.isReady)")
        print("Configuration status: \(LLMService.shared.configurationStatus)")
        
        // Send message to LLM service
        LLMService.shared.sendMessage(
            messages: conversation.sortedMessages,
            systemPrompt: systemPrompt
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                print("✅ Set isLoading to false")
                
                switch result {
                case .success(let response):
                    print("✅ LLM Response received: \(response)")
                    // Add AI response to conversation
                    _ = manager.addMessage(to: conversation, content: response, role: "ai")
                    print("🤖 Main view: Added AI response to conversation - total messages: \(conversation.messages?.count ?? 0)")
                    
                case .failure(let error):
                    print("❌ LLM Error: \(error)")
                    // Show user-friendly error message
                    errorMessage = error.userMessage
                    
                    // Add a fallback message to keep conversation flowing
                    let fallbackMessage = "I apologize, but I'm having trouble responding right now. Please try again in a moment."
                    _ = manager.addMessage(to: conversation, content: fallbackMessage, role: "ai")
                }
            }
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
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)
        let startDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 14))!
        let endDate = calendar.date(byAdding: .day, value: 41, to: startDate)! // 6 weeks - 1 day
        return startDate...endDate
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
    @Binding var systemPrompt: String
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            CustomHeaderView()
            
            // Content area with gradient overlays
            ZStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 20) {
                    // System prompt section with gradient overlay
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
                            .padding(.top, 4) // Push text content below gradient
                            .focused($isTextFieldFocused)
                            .lineSpacing(5) // Adjust line height here
                    }
                    .overlay(
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
                        .offset(y: 32) // Position after the title
                        .allowsHitTesting(false),
                        alignment: .top
                    )
                    
                    Spacer()
                }
                
            }
            
            // Settings Footer with Gradient
            FooterWithGradient(gradientHeight: 24, gradientOffset: -52) {
                HStack(alignment: .top, spacing: 0) {
                    Button(action: {
                        // Update system prompt action
                        dismiss()
                    }) {
                        Text("Update")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 0)
                .padding(.bottom, 16)
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

// MARK: - Custom Calendar View

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let dateRange: ClosedRange<Date>
    
    private let calendar = Calendar.current
    private let today = Date() // Use actual current date
    
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
    @State private var conversation: Conversation?
    
    private let calendar = Calendar.current
    private let today = Date() // Use actual current date
    
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
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)
        let startDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 14))!
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
                // Summary for elapsed days - will show actual conversation summary when available
                if let conversation = conversation,
                   let summary = conversation.summary, !summary.isEmpty {
                    Text(summary)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                } else if conversation?.hasMessages == true {
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
                if let conversation = conversation,
                   conversation.hasMessages {
                    VStack(alignment: .leading, spacing: 16) {
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
                }
            } else if isToday {
                // Today's conversation (in progress)
                if let conversation = conversation,
                   conversation.hasMessages {
                    Text("Today's conversation is in progress.")
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    // Show messages from today's conversation
                    VStack(alignment: .leading, spacing: 16) {
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
        .onAppear {
            loadConversation()
        }
        .onChange(of: date) { _, _ in
            loadConversation()
        }
    }
    
    private func loadConversation() {
        conversation = CoreDataManager.shared.fetchConversation(for: date)
        print("📅 Calendar: Loaded conversation for \(date)")
        print("   - isElapsed: \(isElapsed)")
        print("   - isToday: \(isToday)")
        print("   - isFuture: \(isFuture)")
        print("   - conversation exists: \(conversation != nil)")
        print("   - hasMessages: \(conversation?.hasMessages == true)")
        print("   - hasSummary: \(conversation?.summary?.isEmpty == false)")
        if let conv = conversation {
            print("   - message count: \(conv.messages?.count ?? 0)")
            print("   - conversation date: \(conv.date ?? Date())")
        }
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

// MARK: - Compact Breathwork Timer for Loading

struct CompactBreathworkTimerView: View {
    @State private var currentPhase = "Breathe In"
    @State private var remainingSeconds = 1
    @State private var currentCycle = 0
    @State private var timer: Timer?
    @State private var isCountingUp = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 16) {
                // Compact circular timer
                VStack(spacing: 12) {
                    Text(currentPhase)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                    
                    ZStack {
                        Circle()
                            .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 2)
                            .frame(width: 60, height: 60)
                        
                        Text("\(remainingSeconds)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            // Reset timer to beginning state every time it appears
            resetTimer()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
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
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        // Reset to beginning state
        currentPhase = "Breathe In"
        remainingSeconds = 1
        isCountingUp = true
    }
    
    private func nextPhase() {
        // Breathwork phase cycling with specific countdown patterns
        switch currentPhase {
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
            currentPhase = "Breathe In"
            remainingSeconds = 1
            isCountingUp = true
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

// MARK: - Reusable Footer Component

struct FooterWithGradient<Content: View>: View {
    let gradientHeight: CGFloat
    let gradientOffset: CGFloat
    let gradientColors: [Color]
    @ViewBuilder let content: () -> Content
    
    init(
        gradientHeight: CGFloat = 24,
        gradientOffset: CGFloat = 16, // Fixed offset from footer top
        gradientColors: [Color] = [.black.opacity(0.9), .black.opacity(0.6), .black.opacity(0.2), .clear],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.gradientHeight = gradientHeight
        self.gradientOffset = gradientOffset
        self.gradientColors = gradientColors
        self.content = content
    }
    
    var body: some View {
        content()
            .overlay(
                // Gradient positioned relative to footer top
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: gradientHeight)
                .offset(y: gradientOffset) // Negative offset moves gradient up from footer
                .allowsHitTesting(false),
                alignment: .top // Align to footer top
            )
    }
}

