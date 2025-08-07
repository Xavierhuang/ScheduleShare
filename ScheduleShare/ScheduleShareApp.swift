//
//  ScheduleShareApp.swift
//  ScheduleShare
//
//  Created by Weijia Huang on 8/4/25.
//

import SwiftUI

@main
struct ScheduleShareApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var calendarManager = CalendarManager()
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(appState)
                .environmentObject(calendarManager)
        }
    }
}

struct MainAppView: View {
    @State private var showingSplash = true
    
    var body: some View {
        Group {
            if showingSplash {
                SplashView()
                    .onAppear {
                        print("🎬 Splash screen appeared")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            print("🎬 Transitioning to main app")
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showingSplash = false
                            }
                        }
                    }
            } else {
                ContentView()
                    .onAppear {
                        print("📱 Main app appeared")
                    }
            }
        }
    }
}
