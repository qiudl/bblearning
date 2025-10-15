//
//  ContentView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

// ContentView and AppState are now defined in BBLearningApp.swift
// This file exists for organizational purposes and can contain extensions or previews

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
#endif
