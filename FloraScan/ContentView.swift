//
//  ContentView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        if hasOnboarded {
            RootTabView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
