//
//  AdvancedSplashView.swift
//  ScheduleShare
//
//  Created by Weijia Huang on 8/5/25.
//

import SwiftUI
import EventKit

struct AdvancedSplashView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var titleOpacity: Double = 0.0
    @State private var progressOpacity: Double = 0.0
    @State private var loadingProgress: Double = 0.0
    @State private var loadingText = "Initializing..."
    
    @StateObject private var appState = AppState()
    @StateObject private var calendarManager = CalendarManager()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // App Logo/Icon
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // App Title
                VStack(spacing: 8) {
                    Text("ScheduleShare")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Save & Share Events")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
                .opacity(titleOpacity)
                
                // Loading progress
                VStack(spacing: 12) {
                    ProgressView(value: loadingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(width: 200)
                    
                    Text(loadingText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(progressOpacity)
            }
        }
        .onAppear {
            startSplashAnimation()
        }
        .fullScreenCover(isPresented: $isActive) {
            ContentView()
                .environmentObject(appState)
                .environmentObject(calendarManager)
        }
    }
    
    private func startSplashAnimation() {
        // Animate logo entrance
        withAnimation(.easeInOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Animate title entrance
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            titleOpacity = 1.0
        }
        
        // Show progress indicator
        withAnimation(.easeInOut(duration: 0.5).delay(0.6)) {
            progressOpacity = 1.0
        }
        
        // Simulate loading tasks
        simulateLoadingTasks()
    }
    
    private func simulateLoadingTasks() {
        let tasks = [
            ("Loading events...", 0.2),
            ("Checking calendar permissions...", 0.4),
            ("Initializing AI services...", 0.6),
            ("Preparing sharing features...", 0.8),
            ("Ready!", 1.0)
        ]
        
        for (index, (text, progress)) in tasks.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double(index) * 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loadingText = text
                    loadingProgress = progress
                }
                
                // Transition to main app after last task
                if index == tasks.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AdvancedSplashView()
} 