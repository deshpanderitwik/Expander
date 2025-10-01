//
//  DayView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI

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
