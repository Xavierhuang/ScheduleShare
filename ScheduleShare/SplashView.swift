//
//  SplashView.swift
//  ScheduleShare
//
//  Created by Weijia Huang on 8/5/25.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var titleOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo/Icon
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
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
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .opacity(titleOpacity)
            }
        }
        .onAppear {
            // Animate logo entrance
            withAnimation(.easeInOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Animate title entrance
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                titleOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
} 