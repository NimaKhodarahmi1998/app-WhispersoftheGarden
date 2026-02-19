//
//  SFXGenerator.swift
//  WhispersoftheGardenApp
//
//  Synthesized sound effects — extremely soft, calming, organic.
//  Every sound is designed to feel like it belongs in a quiet Persian garden.
//

import AVFoundation

enum SFXType: CaseIterable {
    case waterDrop
    case lilyPadAppear
    case lotusBloom
    case poemReveal
    case poemDismiss
    case nightingaleChirp
    case wingFlutter
    case whisperTone
    case petalWhoosh
    case gentleTap
}

enum SFXGenerator {

    static func generateBuffer(for type: SFXType, sampleRate: Double) -> AVAudioPCMBuffer {
        switch type {
        case .waterDrop:       return waterDrop(sampleRate: sampleRate)
        case .lilyPadAppear:   return lilyPadAppear(sampleRate: sampleRate)
        case .lotusBloom:      return lotusBloom(sampleRate: sampleRate)
        case .poemReveal:      return poemReveal(sampleRate: sampleRate)
        case .poemDismiss:     return poemDismiss(sampleRate: sampleRate)
        case .nightingaleChirp: return nightingaleChirp(sampleRate: sampleRate)
        case .wingFlutter:     return wingFlutter(sampleRate: sampleRate)
        case .whisperTone:     return whisperTone(sampleRate: sampleRate)
        case .petalWhoosh:     return petalWhoosh(sampleRate: sampleRate)
        case .gentleTap:       return gentleTap(sampleRate: sampleRate)
        }
    }

    // MARK: - Water Drop (0.6s)
    // A gentle plop — soft sine with slow attack, warm harmonics, like a pebble in a still pool.

    private static func waterDrop(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 0.6
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        var phase1: Double = 0
        var phase2: Double = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Soft attack (8ms rise), then gentle exponential decay
            let attack = min(t / 0.008, 1.0)
            let decay = exp(-t * 5.0)
            let env = attack * decay

            // Descending tone: 420 → 280 Hz (gentle glide, not a chirp)
            let freq1 = 420.0 - 140.0 * (t / duration)
            phase1 += 2.0 * .pi * freq1 / sampleRate
            let tone1 = sin(phase1) * 0.6

            // Warm 2nd harmonic, softer
            let freq2 = freq1 * 2.0
            phase2 += 2.0 * .pi * freq2 / sampleRate
            let tone2 = sin(phase2) * 0.15

            data[i] = Float((tone1 + tone2) * env) * 0.10
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Lily Pad Appear (0.5s)
    // A single water droplet — tiny impact transient, then a descending bubble tone
    // with slight frequency jitter (trapped air wobble). Soft and natural.

    private static func lilyPadAppear(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 0.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        var phase: Double = 0
        var noiseFilter: Float = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // --- Layer 1: Impact transient (first ~8ms) ---
            // Tiny click of water surface breaking — filtered noise burst
            let impactEnv = exp(-t * 500.0)  // extremely fast decay
            let noise = Float.random(in: -1...1)
            noiseFilter = noiseFilter + 0.3 * (noise - noiseFilter)
            let impact = Double(noiseFilter) * impactEnv * 0.6

            // --- Layer 2: Bubble tone ---
            // Descending frequency: 650 → 320 Hz (air bubble rising and shrinking)
            // Exponential descent — fast at first, slows down (natural bubble physics)
            let freqDecay = exp(-t * 4.0)
            let baseFreq = 320.0 + 330.0 * freqDecay

            // Frequency jitter — trapped air wobble, subtle and organic
            let jitter = sin(2.0 * .pi * 18.0 * t) * 12.0 * exp(-t * 3.0)

            let freq = baseFreq + jitter
            phase += 2.0 * .pi * freq / sampleRate

            // Bubble envelope: quick attack (3ms), then exponential decay
            let bubbleAttack = min(t / 0.003, 1.0)
            let bubbleDecay = exp(-t * 6.5)
            let bubbleEnv = bubbleAttack * bubbleDecay

            // Slightly saturated sine for warmth (not pure)
            let raw = sin(phase)
            let bubble = raw - 0.15 * raw * raw * raw  // gentle cubic soft-clip

            let sample = (impact + bubble * bubbleEnv) * 0.11

            data[i] = Float(sample)
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Lotus Bloom (2.0s)
    // A warm opening — breath and warmth slowly spreading, like light hitting a flower.
    // Filtered noise bed with a rich tone emerging via wave-shaping (no pure sines).

    private static func lotusBloom(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 2.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        var noiseFilter: Float = 0
        var phase1: Double = 0  // D4, slightly detuned pair
        var phase2: Double = 0
        var phase3: Double = 0  // A4, enters later

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / duration

            // Overall envelope: very slow quadratic rise (500ms), long fade
            let attack = min(t / 0.5, 1.0)
            let attackShaped = attack * attack  // quadratic ease-in
            let decay = exp(-(t - 0.6) * 1.2)
            let env = attackShaped * min(decay, 1.0)

            // Layer 1: Breathy noise bed — warm filtered noise, cutoff sweeps upward
            let noise = Float.random(in: -1...1)
            let noiseCutoff: Float = Float(0.03 + 0.04 * progress)
            noiseFilter = noiseFilter + noiseCutoff * (noise - noiseFilter)
            let breathLayer = Double(noiseFilter) * 1.8

            // Layer 2: Warm tone emerging via wave-shaping (NOT pure sine)
            // Drive increases over time: silence → rich harmonics ("blooming")
            let drive = min(t / 0.8, 1.0) * 1.4
            let freq1 = 293.66 + sin(t * 0.7) * 1.2  // D4 with micro-drift
            let freq2 = 294.5 + sin(t * 0.9) * 1.0    // Slightly detuned D4 (chorus)
            phase1 += 2.0 * .pi * freq1 / sampleRate
            phase2 += 2.0 * .pi * freq2 / sampleRate

            // Wave-shaping: tanh(sin(x) * drive) produces evolving harmonics
            let raw1 = sin(phase1) * drive
            let raw2 = sin(phase2) * drive * 0.8
            let shaped1 = drive > 0.01 ? tanh(raw1) / tanh(drive) : 0
            let shaped2 = drive > 0.01 ? tanh(raw2) / tanh(drive * 0.8) : 0
            let toneLayer = (shaped1 + shaped2) * 0.25

            // Layer 3: High shimmer (A4) enters at the peak, very faint
            let shimmerStart: Double = 0.7
            let shimmerEnv: Double
            if t > shimmerStart {
                let shimmerT = t - shimmerStart
                let shimmerAttack = min(shimmerT / 0.3, 1.0)
                let shimmerDecay = exp(-shimmerT * 1.5)
                shimmerEnv = shimmerAttack * shimmerDecay * 0.15
            } else {
                shimmerEnv = 0
            }
            let freq3 = 440.0 + sin(t * 1.1) * 1.5
            phase3 += 2.0 * .pi * freq3 / sampleRate
            let shimmerLayer = sin(phase3 + sin(phase3 * 2.0) * 0.2) * shimmerEnv

            let mixed = (breathLayer * 0.4 + toneLayer + shimmerLayer) * env
            data[i] = Float(mixed) * 0.09
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Poem Reveal (1.0s)
    // Gentle ascending shimmer — like light catching golden script.

    private static func poemReveal(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 1.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        var phase: Double = 0
        var filtered: Float = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Slow rise, then gentle fade
            let attack = min(t / 0.15, 1.0)
            let decay = exp(-(t - 0.2) * 2.0)
            let env = attack * max(decay, 0)

            // Gently ascending pitch: D4 → A4 over the duration
            let freq = 293.66 + 146.34 * (t / duration)
            let vibrato = sin(2.0 * .pi * 5.0 * t) * 2.0
            phase += 2.0 * .pi * (freq + vibrato) / sampleRate
            let tone = sin(phase) * 0.4

            // Soft breathy layer — filtered noise, very quiet
            let noise = Float.random(in: -1...1)
            let cutoff: Float = Float(0.03 + 0.04 * sin(.pi * t / duration))
            filtered = filtered + cutoff * (noise - filtered)
            let breath = Double(filtered) * 0.3

            data[i] = Float((tone + breath) * env) * 0.08
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Poem Dismiss (0.5s)
    // Gentle descending release — like setting down a scroll with a sigh.

    private static func poemDismiss(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 0.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        var phase: Double = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // No harsh onset — starts at full then gently fades
            let env = exp(-t * 4.0)

            // Gently descending: A4 → D4
            let freq = 440.0 - 146.34 * (t / duration)
            let vibrato = sin(2.0 * .pi * 4.5 * t) * 2.0
            phase += 2.0 * .pi * (freq + vibrato) / sampleRate
            let tone = sin(phase) * 0.5

            // Faint 2nd partial
            let partial = sin(phase * 2.0) * 0.1

            data[i] = Float((tone + partial) * env) * 0.07
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Nightingale Chirp (1.0s)
    // Gentle bird song — 3 soft pure notes with vibrato, like a distant nightingale.
    // Phase-continuous for smooth pitch transitions.

    private static func nightingaleChirp(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 1.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        // 3 gentle notes with gaps
        // Note 1: 0.00-0.20s  Note 2: 0.30-0.50s  Note 3: 0.60-0.85s
        let noteStarts: [Double] = [0.0, 0.30, 0.60]
        let noteEnds: [Double] = [0.20, 0.50, 0.85]
        let noteFreqs: [Double] = [1100.0, 1450.0, 1250.0] // ascending then settling

        var phase: Double = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Find which note (if any) is active
            var noteAmp: Double = 0
            var freq: Double = 1100.0

            for n in 0..<3 {
                if t >= noteStarts[n] && t < noteEnds[n] {
                    let noteT = t - noteStarts[n]
                    let noteDur = noteEnds[n] - noteStarts[n]
                    let progress = noteT / noteDur

                    // Gaussian-like envelope: smooth rise and fall, no harsh edges
                    noteAmp = sin(.pi * progress)

                    // Base frequency with gentle pitch contour (slight rise then fall within each note)
                    let pitchBend = sin(.pi * progress) * 40.0
                    freq = noteFreqs[n] + pitchBend

                    break
                }
            }

            // Vibrato: natural bird-like tremolo (6Hz, ±25Hz)
            let vibrato = sin(2.0 * .pi * 6.0 * t) * 25.0

            phase += 2.0 * .pi * (freq + vibrato) / sampleRate
            let tone = sin(phase)

            data[i] = Float(tone * noteAmp) * 0.06
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Wing Flutter (0.5s)
    // Barely audible air movement — the softest breath of feathers.

    private static func wingFlutter(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 0.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        var filtered: Float = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Gentle bell-curve envelope
            let center = duration * 0.35
            let width = duration * 0.25
            let env = exp(-pow((t - center) / width, 2))

            // Very gentle AM at 10Hz (not 25 — softer flutter)
            let am = sin(2.0 * .pi * 10.0 * t) * 0.4 + 0.6

            // Low-frequency filtered noise (very warm)
            let noise = Float.random(in: -1...1)
            filtered = filtered + 0.06 * (noise - filtered) // very low cutoff
            let shaped = Double(filtered) * 3.0

            data[i] = Float(shaped * am * env) * 0.04
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Whisper Tone (1.5s)
    // Breathy and warm — like the garden whispering a secret.

    private static func whisperTone(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 1.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        var filtered: Float = 0
        var phase: Double = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Very slow attack (200ms), long gentle decay
            let attack = min(t / 0.2, 1.0)
            let decay = exp(-t * 1.5)
            let env = Float(attack * decay)

            // Warm filtered noise
            let noise = Float.random(in: -1...1)
            filtered = filtered + 0.05 * (noise - filtered)

            // Faint pitched hum underneath (D4)
            phase += 2.0 * .pi * 293.66 / sampleRate
            let hum = Float(sin(phase)) * 0.04 * Float(decay)

            data[i] = (filtered * 2.0 + hum) * env * 0.05
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Petal Whoosh (0.7s)
    // The gentlest breeze — barely there, like petals drifting.

    private static func petalWhoosh(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 0.7
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        var filtered: Float = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / duration

            // Bell-curve centered at 30% through — swoosh peaks early then fades
            let env = exp(-pow((progress - 0.3) / 0.22, 2))

            // Sweeping lowpass: cutoff rises then falls with the envelope
            let cutoff: Float = Float(0.02 + 0.08 * sin(.pi * progress))

            let noise = Float.random(in: -1...1)
            filtered = filtered + cutoff * (noise - filtered)

            data[i] = filtered * 2.5 * Float(env) * 0.05
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Gentle Tap (0.15s)
    // The lightest touch — a single soft tone, like a fingertip on water.

    private static func gentleTap(sampleRate: Double) -> AVAudioPCMBuffer {
        let duration: Double = 0.15
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = makeBuffer(frameCount: frameCount, sampleRate: sampleRate)
        let data = buffer.floatChannelData![0]

        var phase: Double = 0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Soft attack (3ms), smooth decay
            let attack = min(t / 0.003, 1.0)
            let decay = exp(-t * 25.0)
            let env = attack * decay

            // Warm, low tone
            phase += 2.0 * .pi * 480.0 / sampleRate
            let tone = sin(phase) * 0.5

            data[i] = Float(tone * env) * 0.07
        }

        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Helpers

    private static func makeBuffer(frameCount: AVAudioFrameCount, sampleRate: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
    }
}
