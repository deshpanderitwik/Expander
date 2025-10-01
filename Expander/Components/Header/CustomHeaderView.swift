//
//  CustomHeaderView.swift
//  Expander
//
//  Created by Rit on 9/13/25.
//

import SwiftUI

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
