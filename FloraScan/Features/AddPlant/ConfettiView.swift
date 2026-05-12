//
//  ConfettiView.swift
//  FloraScan
//
//  Created by José Luis Corral López on 28/4/26.
//

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    @State private var opacity: Double = 1

    private let count = 40

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Image(systemName: "leaf.fill")
                    .font(.system(size: p.size))
                    .foregroundStyle(p.color)
                    .rotationEffect(.degrees(p.rotation))
                    .offset(x: p.x, y: p.y)
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .onAppear {
            generateParticles()
            withAnimation(.easeOut(duration: 1.5)) {
                animateParticles()
            }
            withAnimation(.easeIn(duration: 0.4).delay(1.1)) {
                opacity = 0
            }
        }
    }

    private func generateParticles() {
        let colors: [Color] = [
            Palette.leaf700, Palette.leaf500, Palette.leaf300,
            Palette.amber500, Palette.leaf100
        ]
        particles = (0..<count).map { _ in
            Particle(
                x: CGFloat.random(in: -160...160),
                y: 0,
                targetY: CGFloat.random(in: 200...600),
                rotation: Double.random(in: 0...360),
                targetRotation: Double.random(in: -180...540),
                size: CGFloat.random(in: 8...16),
                color: colors.randomElement() ?? Palette.leaf700
            )
        }
    }

    private func animateParticles() {
        for i in particles.indices {
            particles[i].y = particles[i].targetY
            particles[i].x += CGFloat.random(in: -80...80)
            particles[i].rotation = particles[i].targetRotation
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var targetY: CGFloat
    var rotation: Double
    var targetRotation: Double
    var size: CGFloat
    var color: Color
}
