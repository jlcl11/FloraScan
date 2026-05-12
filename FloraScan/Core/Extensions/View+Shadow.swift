//
//  View+Shadow.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    func fsShadow(_ level: Int) -> some View {
        switch level {
        case 1: self.shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        case 2: self.shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        case 3: self.shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: 8)
        case 4: self.shadow(color: .black.opacity(0.14), radius: 40, x: 0, y: 16)
        default: self
        }
    }
}
