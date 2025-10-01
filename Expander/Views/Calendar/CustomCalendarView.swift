//
//  CustomCalendarView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI

struct CustomCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    private let calendar = Calendar.current
    private let today = Date() // Use actual current date
    
    var body: some View {
        VStack(spacing: 16) {            
            // Day of week headers
            HStack {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(viewModel.calendarDays, id: \.self) { date in
                    DayView(
                        date: date,
                        isSelected: viewModel.isDateSelected(date),
                        isToday: viewModel.isDateToday(date),
                        isInRange: viewModel.isDateInRange(date),
                        isFuture: viewModel.isDateFuture(date)
                    ) {
                        viewModel.selectDate(date)
                    }
                }
            }
        }
    }
}
