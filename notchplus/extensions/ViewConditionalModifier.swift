//
//  ViewConditionalModifier.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 21/10/24.
//

import SwiftUI

extension View {
    @ViewBuilder func conditionalModifier<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
