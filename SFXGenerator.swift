//
//  SFXGenerator.swift
//  WhispersoftheGardenApp
//
//  Sensory feedback: sound effect types + haptic feedback.
//

import UIKit

enum SFXType {
    case waterDrop, lilyPadAppear, lotusBloom, poemReveal, poemDismiss
    case nightingaleChirp, wingFlutter, whisperTone, petalWhoosh, gentleTap
}

// MARK: - Haptic Feedback

/// Garden-aware haptics — every touch should feel like the garden responding.
/// Intensities are deliberately low; this is a calming, meditative app.
enum Haptics {

    /// Finger touches still water — soft yielding ripple.
    static func waterTouch() {
        let gen = UIImpactFeedbackGenerator(style: .soft)
        gen.impactOccurred(intensity: 0.40)
    }

    /// Lily pad transforms into a lotus — a gentle unfolding.
    static func lotusBloom() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred(intensity: 0.50)
    }

    /// Poem overlay closes — the softest release.
    static func poemDismiss() {
        let gen = UIImpactFeedbackGenerator(style: .soft)
        gen.impactOccurred(intensity: 0.25)
    }

    /// Tapping the nightingale — a flutter under the fingertip.
    static func nightingaleTap() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred(intensity: 0.50)
    }

    /// Nightingale lands on a branch — the weight of a small bird alighting.
    static func nightingaleLanding() {
        let gen = UIImpactFeedbackGenerator(style: .soft)
        gen.impactOccurred(intensity: 0.35)
    }

    /// Tab switch — a subtle page turn between garden and library.
    static func tabSwitch() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred(intensity: 0.30)
    }
}
