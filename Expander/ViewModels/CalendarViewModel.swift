//
//  CalendarViewModel.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI
import Foundation

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    
    private let calendar = Calendar.current
    
    // MARK: - Date Range
    
    var dateRange: ClosedRange<Date> {
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!
        // Show 6 weeks from the start date (42 days total)
        let endDate = calendar.date(byAdding: .day, value: 41, to: startDate)! // 6 weeks - 1 day
        return startDate...endDate
    }
    
    var calendarDays: [Date] {
        // Only show dates within our selected timeframe
        var days: [Date] = []
        var currentDate = dateRange.lowerBound
        
        while currentDate <= dateRange.upperBound {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    // MARK: - Date Utilities
    
    func isDateInRange(_ date: Date) -> Bool {
        return dateRange.contains(date)
    }
    
    func isDateToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: Date())
    }
    
    func isDateSelected(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    func isDateFuture(_ date: Date) -> Bool {
        return date > Date()
    }
    
    func selectDate(_ date: Date) {
        if isDateInRange(date) {
            selectedDate = date
        }
    }
    
    // MARK: - Day Number Calculation
    
    func dayNumber(for date: Date) -> Int {
        let startDate = calendar.startOfDay(for: calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!)
        let dayDiff = calendar.dateComponents([.day], from: startDate, to: calendar.startOfDay(for: date)).day!
        return dayDiff
    }
}
