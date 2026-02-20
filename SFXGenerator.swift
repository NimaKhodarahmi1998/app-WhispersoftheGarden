//
//  SFXGenerator.swift
//  WhispersoftheGardenApp
//
//  Sensory feedback: sound effect buffer generation + haptic feedback.
//  All sounds are physically-modeled or DSP-synthesized — no audio files.
//
//  Design principles:
//  - Everything extremely soft and calming — like the garden breathing
//  - No harsh frequencies; nothing above ~1 kHz for poem sounds
//  - Exponential envelopes only (no linear), slow attacks (200ms+)
//  - Pink noise (never white), always lowpassed
//  - tanh waveshaping for organic warmth
//  - All amplitudes very low (0.02-0.08 range)
//

import UIKit

enum SFXType {
    case waterDrop, lilyPadAppear, lotusBloom, poemReveal, poemDismiss
    case nightingaleChirp, nightingaleFarewell
    case wingFlutter, wingDeparture, whisperTone, petalWhoosh, gentleTap
}

// MARK: - SFX Buffer Generation

enum SFXBufferGen {

    private static let twoPi: Float = 2.0 * Float.pi

    // MARK: Public Dispatch

    static func generate(_ type: SFXType, sampleRate sr: Double) -> [Float] {
        switch type {
        case .waterDrop:        return waterDrop(sr: sr)
        case .lilyPadAppear:    return lilyPadAppear(sr: sr)
        case .lotusBloom:       return lotusBloom(sr: sr)
        case .poemReveal:       return poemReveal(sr: sr)
        case .poemDismiss:      return poemDismiss(sr: sr)
        case .nightingaleChirp:    return nightingaleChirp(sr: sr)
        case .nightingaleFarewell: return nightingaleFarewell(sr: sr)
        case .wingFlutter:         return wingFlutter(sr: sr)
        case .wingDeparture:       return wingDeparture(sr: sr)
        case .whisperTone:      return whisperTone(sr: sr)
        case .petalWhoosh:      return petalWhoosh(sr: sr)
        case .gentleTap:        return gentleTap(sr: sr)
        }
    }

    // MARK: - DSP Helpers

    /// Voss-McCartney pink noise (1/f spectrum, pre-initialized)
    private static func pinkNoise(count: Int) -> [Float] {
        var output = [Float](repeating: 0, count: count)
        var gens = [Float](repeating: 0, count: 8)
        var sum: Float = 0
        for g in 0..<8 {
            gens[g] = Float.random(in: -1...1)
            sum += gens[g]
        }
        for i in 0..<count {
            let idx = i == 0 ? 0 : min(i.trailingZeroBitCount, 7)
            sum -= gens[idx]
            gens[idx] = Float.random(in: -1...1)
            sum += gens[idx]
            output[i] = sum / 8.0
        }
        return output
    }

    /// One-pole IIR lowpass (in-place)
    private static func lowpass(_ buf: inout [Float], cutoff: Double, sr: Double) {
        guard buf.count > 1 else { return }
        let alpha = Float(1.0 / (1.0 + sr / (2.0 * Double.pi * cutoff)))
        var prev = buf[0]
        for i in 1..<buf.count {
            buf[i] = prev + alpha * (buf[i] - prev)
            prev = buf[i]
        }
    }

    /// Chamberlin state-variable bandpass filter
    private static func bandpass(_ input: [Float], center: Double, q: Double, sr: Double) -> [Float] {
        var output = [Float](repeating: 0, count: input.count)
        let f = 2.0 * sin(Float.pi * Float(center / sr))
        let qInv = Float(1.0 / q)
        var low: Float = 0, band: Float = 0
        for i in 0..<input.count {
            low += f * band
            let high = input[i] - low - qInv * band
            band += f * high
            output[i] = band
        }
        return output
    }

    /// Raised-cosine fade on buffer edges (click prevention)
    private static func fade(_ buf: inout [Float], fadeIn: Int, fadeOut: Int) {
        let fin = min(fadeIn, buf.count)
        for i in 0..<fin {
            buf[i] *= 0.5 * (1.0 - cos(Float.pi * Float(i) / Float(fin)))
        }
        let start = max(0, buf.count - fadeOut)
        for i in start..<buf.count {
            let r = Float(buf.count - 1 - i) / Float(max(1, fadeOut))
            buf[i] *= 0.5 * (1.0 - cos(Float.pi * r))
        }
    }

    /// Gentle tanh saturation — adds warmth without audible distortion
    private static func saturate(_ buf: inout [Float], drive: Float = 1.2) {
        for i in 0..<buf.count { buf[i] = tanh(drive * buf[i]) }
    }

    // MARK: - 1. Water Drop (Minnaert bubble resonance)
    //
    // A single raindrop touching still water — delicate and intimate.
    // Primary bubble at ~480 Hz with gentle frequency chirp (rising pitch
    // as the bubble shrinks). Secondary bubble adds depth. Very soft
    // micro-splash — more of a surface tension whisper than a splash.

    private static func waterDrop(sr: Double) -> [Float] {
        let count = Int(0.22 * sr)
        var buf = [Float](repeating: 0, count: count)

        // Primary bubble (~480 Hz, gentle upward chirp from shrinking bubble)
        let f0 = Float.random(in: 450...510)
        let beta0: Float = 38.0
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let freq = f0 * (1.0 + 0.12 * beta0 * t)
            buf[i] += 0.05 * exp(-beta0 * t) * sin(twoPi * freq * t)
        }

        // Secondary bubble (~750 Hz, faster decay — adds roundness)
        let f1 = Float.random(in: 700...800)
        let beta1: Float = 60.0
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            buf[i] += 0.02 * exp(-beta1 * t) * sin(twoPi * f1 * t)
        }

        // Tertiary resonance (~1400 Hz, very brief sparkle)
        let f2 = Float.random(in: 1300...1500)
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            buf[i] += 0.006 * exp(-120.0 * t) * sin(twoPi * f2 * t)
        }

        // Micro-splash: lowpassed pink noise (surface tension whisper, 4 ms)
        var splash = pinkNoise(count: min(Int(0.005 * sr), count))
        lowpass(&splash, cutoff: 1200, sr: sr)
        for i in 0..<splash.count where i < count {
            let e = 1.0 - Float(i) / Float(splash.count)
            buf[i] += 0.008 * e * e * splash[i]
        }

        fade(&buf, fadeIn: 4, fadeOut: Int(0.025 * sr))
        saturate(&buf, drive: 1.1)
        return buf
    }

    // MARK: - 2. Lily Pad Appear (soft watery surface tension)
    //
    // A lily pad emerging from still water — the gentlest disturbance.
    // Low warm tone with slow waveshaping bloom, filtered water texture.

    private static func lilyPadAppear(sr: Double) -> [Float] {
        let count = Int(0.6 * sr)
        var buf = [Float](repeating: 0, count: count)

        // Warm low tone (~190 Hz) with very gentle waveshaping
        let f0 = Float.random(in: 185...200)
        let f1 = f0 + Float.random(in: 0.2...0.5) // gentle detuning/beating
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let att = 1.0 - exp(-t / 0.12)
            let rel = exp(-max(0, t - 0.2) / 0.25)
            let env = att * rel
            buf[i] += 0.04 * env * tanh(1.2 * sin(twoPi * f0 * t))
            buf[i] += 0.02 * env * sin(twoPi * f1 * t)
        }

        // Filtered pink noise for gentle water texture
        var pn = pinkNoise(count: count)
        lowpass(&pn, cutoff: 500, sr: sr)
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            buf[i] += 0.012 * (1.0 - exp(-t / 0.06)) * exp(-t / 0.3) * pn[i]
        }

        fade(&buf, fadeIn: 8, fadeOut: Int(0.05 * sr))
        saturate(&buf, drive: 1.1)
        return buf
    }

    // MARK: - 3. Lotus Bloom (organic growth)
    //
    // A seed becoming a flower. The sound GROWS:
    //  - Starts as a single quiet tone (the seed)
    //  - Pitch slowly rises (reaching toward light)
    //  - New voices enter one by one (petals opening)
    //  - Detuning widens over time (the bloom spreading)
    //  - Noise brightens as cutoff rises (the world opening up)
    //  - Peaks at full complexity, then gently settles

    private static func lotusBloom(sr: Double) -> [Float] {
        let dur: Float = 3.0
        let count = Int(Double(dur) * sr)
        var buf = [Float](repeating: 0, count: count)
        let dt = Float(1.0 / sr)

        let startFreq = Float.random(in: 195...210)  // seed
        let endFreq   = startFreq * 1.35              // ~major 4th up

        // Voice 1 — the seed: enters immediately, rises in pitch
        var ph1: Float = 0
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let n = t / dur
            let freq = startFreq + (endFreq - startFreq) * (1.0 - exp(-n * 2.5))
            ph1 += twoPi * freq * dt
            // Slow swell: 400ms attack, sustain, then gentle fade
            let att = 1.0 - exp(-t / 0.4)
            let rel: Float = t < 2.0 ? 1.0 : exp(-(t - 2.0) / 0.6)
            buf[i] += 0.025 * att * rel * tanh(1.2 * sin(ph1))
        }

        // Voice 2 — first petal: enters at 0.4s, detuned and widening
        var ph2: Float = Float.random(in: 0...twoPi)
        let entry2: Float = 0.4
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            guard t > entry2 else { continue }
            let lt = t - entry2
            let n = t / dur
            let freq = startFreq + (endFreq - startFreq) * (1.0 - exp(-n * 2.5))
            // Detuning widens: 0.2 Hz at entry → 1.2 Hz at peak
            let detune = 0.2 + 1.0 * min(1.0, lt / 2.0)
            ph2 += twoPi * (freq + detune) * dt
            let att = 1.0 - exp(-lt / 0.5)
            let rel: Float = t < 2.2 ? 1.0 : exp(-(t - 2.2) / 0.5)
            buf[i] += 0.02 * att * rel * tanh(1.2 * sin(ph2))
        }

        // Voice 3 — second petal: enters at 0.8s, opposite detune
        var ph3: Float = Float.random(in: 0...twoPi)
        let entry3: Float = 0.8
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            guard t > entry3 else { continue }
            let lt = t - entry3
            let n = t / dur
            let freq = startFreq + (endFreq - startFreq) * (1.0 - exp(-n * 2.5))
            let detune = -(0.2 + 0.8 * min(1.0, lt / 2.0))
            ph3 += twoPi * (freq + detune) * dt
            let att = 1.0 - exp(-lt / 0.6)
            let rel: Float = t < 2.4 ? 1.0 : exp(-(t - 2.4) / 0.4)
            buf[i] += 0.015 * att * rel * sin(ph3)
        }

        // Octave shimmer — enters at 1.2s (the bloom is fully open)
        var ph4: Float = Float.random(in: 0...twoPi)
        let entry4: Float = 1.2
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            guard t > entry4 else { continue }
            let lt = t - entry4
            let n = t / dur
            let freq = startFreq + (endFreq - startFreq) * (1.0 - exp(-n * 2.5))
            ph4 += twoPi * freq * 2.0 * dt
            let att = 1.0 - exp(-lt / 0.8)
            let rel: Float = t < 2.0 ? 1.0 : exp(-(t - 2.0) / 0.4)
            buf[i] += 0.006 * att * rel * sin(ph4)
        }

        // Brightening breath — noise cutoff rises over time (world opening)
        let pn = pinkNoise(count: count)
        let blockSize = 512
        var pos = 0
        while pos < count {
            let end = min(pos + blockSize, count)
            let n = Float(pos) / Float(count)
            // Cutoff rises from 150 Hz → 450 Hz (sound brightens with growth)
            let cutoff = Double(150.0 + 300.0 * n)
            var block = Array(pn[pos..<end])
            lowpass(&block, cutoff: cutoff, sr: sr)
            for j in 0..<block.count {
                let gi = pos + j
                let t = Float(gi) / Float(sr)
                let att = 1.0 - exp(-t / 0.8)
                let rel: Float = t < 2.0 ? 1.0 : exp(-(t - 2.0) / 0.6)
                buf[gi] += 0.01 * att * rel * block[j]
            }
            pos = end
        }

        fade(&buf, fadeIn: 16, fadeOut: Int(0.15 * sr))
        saturate(&buf, drive: 1.1)
        return buf
    }

    // MARK: - 4. Poem Reveal (soft crystal chime)
    //
    // A gentle felt-mallet strike on crystal — brief, warm, musical.
    // Two slightly inharmonic modes (like a real bell/glass) with
    // natural exponential ring-out. Soft raised-cosine excitation
    // prevents any click. The sound is a clear, pleasant "event"
    // rather than droning noise or sustained tone.

    private static func poemReveal(sr: Double) -> [Float] {
        let count = Int(1.2 * sr)
        var buf = [Float](repeating: 0, count: count)

        // Soft excitation pulse (raised-cosine, 25ms — felt mallet)
        let pulseLen = Int(0.025 * sr)
        var pulse = [Float](repeating: 0, count: count)
        for i in 0..<min(pulseLen, count) {
            pulse[i] = 0.5 * (1.0 - cos(twoPi * Float(i) / Float(pulseLen)))
        }

        // Mode 1: Fundamental ~330 Hz (E4) — warm, round
        let f1 = Float.random(in: 320...340)
        let decay1: Float = 0.6 // longer ring
        var phase1: Float = 0
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            phase1 += twoPi * f1 / Float(sr)
            buf[i] += 0.03 * pulse[min(i, pulseLen - 1)] * sin(phase1)
            buf[i] += 0.025 * exp(-t / decay1) * sin(phase1)
        }

        // Mode 2: ~528 Hz (slightly inharmonic — ratio 1.6, like a bell)
        let f2 = f1 * Float.random(in: 1.58...1.62)
        let decay2: Float = 0.4 // shorter ring than fundamental
        var phase2: Float = 0
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            phase2 += twoPi * f2 / Float(sr)
            buf[i] += 0.012 * pulse[min(i, pulseLen - 1)] * sin(phase2)
            buf[i] += 0.01 * exp(-t / decay2) * sin(phase2)
        }

        // Mode 3: Sub-octave warmth ~165 Hz (very quiet, adds body)
        let f3 = f1 * 0.5
        let decay3: Float = 0.5
        var phase3: Float = 0
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            phase3 += twoPi * f3 / Float(sr)
            buf[i] += 0.008 * exp(-t / decay3) * sin(phase3)
        }

        fade(&buf, fadeIn: 4, fadeOut: Int(0.08 * sr))
        saturate(&buf, drive: 1.1)
        return buf
    }

    // MARK: - 5. Poem Dismiss (soft exhale)
    //
    // NO tones, NO sine waves. Pure shaped noise exhale — like a
    // gentle sigh, or a page settling closed. Pink noise with the
    // cutoff sweeping downward (400→100 Hz) so it darkens as it fades.

    private static func poemDismiss(sr: Double) -> [Float] {
        let dur: Float = 0.6
        let count = Int(Double(dur) * sr)
        var buf = [Float](repeating: 0, count: count)

        // Sweeping-cutoff pink noise — process in blocks
        let pn = pinkNoise(count: count)
        let blockSize = 256
        var pos = 0
        while pos < count {
            let end = min(pos + blockSize, count)
            let n = Float(pos) / Float(count)
            // Cutoff sweeps from 400 Hz down to 100 Hz
            let cutoff = Double(400.0 - 300.0 * n)
            var block = Array(pn[pos..<end])
            lowpass(&block, cutoff: cutoff, sr: sr)
            for j in 0..<block.count { buf[pos + j] = block[j] }
            pos = end
        }

        // Shape with a front-loaded envelope
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let att = 1.0 - exp(-t / 0.04)
            let dec = exp(-t / 0.22)
            buf[i] *= 0.05 * att * dec
        }

        fade(&buf, fadeIn: 8, fadeOut: Int(0.06 * sr))
        return buf
    }

    // MARK: - 6. Nightingale Chirp (FM syrinx — ascending arrival call)
    //
    // The nightingale lands: a bright ascending two-voice chirp.
    // FM synthesis models the bifurcated avian syrinx.
    // Ascending pitch contour 2800→3800 Hz with lively 28 Hz vibrato.
    // Two voices (left/right bronchus) for a full, living presence.

    private static func nightingaleChirp(sr: Double) -> [Float] {
        let dur: Float = 0.32
        let count = Int(Double(dur) * sr)
        var buf = [Float](repeating: 0, count: count)
        let dt = Float(1.0 / sr)

        let startF = Float.random(in: 2700...2900)
        let peakF  = startF + Float.random(in: 800...1000)
        let endF   = startF + Float.random(in: 400...600)

        // Pitch jitter (lowpassed noise)
        var jitter = [Float](repeating: 0, count: count)
        for i in 0..<count { jitter[i] = Float.random(in: -1...1) }
        lowpass(&jitter, cutoff: 180, sr: sr)

        // Amplitude flutter
        var flutter = [Float](repeating: 0, count: count)
        for i in 0..<count { flutter[i] = Float.random(in: -1...1) }
        lowpass(&flutter, cutoff: 45, sr: sr)

        // Two voices (bifurcated syrinx)
        for voice in 0..<2 {
            let offset: Float = voice == 0 ? 0 : Float.random(in: 120...160)
            let amp: Float = voice == 0 ? 0.045 : 0.022
            let fmIdx = Float.random(in: 0.25...0.45)
            var cPhase = Float.random(in: 0...twoPi)
            var mPhase = Float.random(in: 0...twoPi)

            for i in 0..<count {
                let t = Float(i) / Float(sr)
                let n = t / dur

                // Log-sigmoid ascending sweep
                let sig = 1.0 / (1.0 + exp(-12.0 * (n - 0.35)))
                var freq = startF + (peakF - startF) * sig
                if n > 0.55 { freq += (n - 0.55) / 0.45 * (endF - peakF) }
                freq += offset + jitter[i] * 8.0
                freq += 40.0 * sin(twoPi * 28.0 * t) // lively vibrato

                mPhase += twoPi * freq * dt
                cPhase += twoPi * freq * dt

                let att = min(1.0, t / 0.006)
                let dec: Float = n > 0.6 ? exp(-(n - 0.6) / 0.18) : 1.0
                let flut = 1.0 + 0.03 * flutter[i]

                buf[i] += amp * att * dec * flut * sin(cPhase + fmIdx * sin(mPhase))
            }
        }

        // Subtle breath noise (bandpassed around carrier)
        var noise = [Float](repeating: 0, count: count)
        for i in 0..<count { noise[i] = Float.random(in: -1...1) }
        let breathN = bandpass(noise, center: 3200, q: 3.0, sr: sr)
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let n = t / dur
            let env = min(1.0, t / 0.004) * (n > 0.6 ? exp(-(n - 0.6) / 0.15) : 1.0)
            buf[i] += 0.003 * env * breathN[i]
        }

        fade(&buf, fadeIn: 4, fadeOut: Int(0.015 * sr))
        return buf
    }

    // MARK: - 6b. Nightingale Farewell (FM syrinx — descending departure)
    //
    // The nightingale says goodbye: a wistful, descending single-voice call.
    // CLEARLY DISTINCT from arrival: single voice (intimate), descending
    // pitch 3600→2200 Hz (wider range), much slower vibrato (12 Hz),
    // very low FM index (purer, more flute-like), longer duration.
    // Like a bird's lingering last note before flying into the distance.

    private static func nightingaleFarewell(sr: Double) -> [Float] {
        let dur: Float = 0.55
        let count = Int(Double(dur) * sr)
        var buf = [Float](repeating: 0, count: count)
        let dt = Float(1.0 / sr)

        let startF = Float.random(in: 3500...3700)
        let endF   = Float.random(in: 2100...2300)

        // Pitch jitter (gentler than arrival)
        var jitter = [Float](repeating: 0, count: count)
        for i in 0..<count { jitter[i] = Float.random(in: -1...1) }
        lowpass(&jitter, cutoff: 120, sr: sr)

        // Amplitude flutter (slower than arrival)
        var flutter = [Float](repeating: 0, count: count)
        for i in 0..<count { flutter[i] = Float.random(in: -1...1) }
        lowpass(&flutter, cutoff: 30, sr: sr)

        // Single voice — intimate, melancholic quality
        let fmIdx = Float.random(in: 0.1...0.22) // very low = purer, sadder
        var cPhase = Float.random(in: 0...twoPi)
        var mPhase = Float.random(in: 0...twoPi)

        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let n = t / dur

            // Smooth descending glide — exponential settling
            var freq = startF + (endF - startF) * (1.0 - exp(-n * 2.8))
            freq += jitter[i] * 6.0
            // Slow, wistful vibrato (12 Hz — half the arrival's rate)
            freq += 25.0 * sin(twoPi * 12.0 * t)

            mPhase += twoPi * freq * dt
            cPhase += twoPi * freq * dt

            // Slow attack, very long fade-out (lingering)
            let att = min(1.0, t / 0.015)
            let dec: Float = n > 0.3 ? exp(-(n - 0.3) / 0.35) : 1.0
            let flut = 1.0 + 0.04 * flutter[i]

            buf[i] += 0.04 * att * dec * flut * sin(cPhase + fmIdx * sin(mPhase))
        }

        // Very subtle breath (lower center, quieter than arrival)
        var noise = [Float](repeating: 0, count: count)
        for i in 0..<count { noise[i] = Float.random(in: -1...1) }
        let breathN = bandpass(noise, center: 2600, q: 2.0, sr: sr)
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let n = t / dur
            let env = min(1.0, t / 0.01) * (n > 0.3 ? exp(-(n - 0.3) / 0.3) : 1.0)
            buf[i] += 0.002 * env * breathN[i]
        }

        fade(&buf, fadeIn: 4, fadeOut: Int(0.06 * sr))
        return buf
    }

    // MARK: - 7. Wing Flutter (approaching flight)
    //
    // A nightingale approaching — AM-modulated filtered noise with
    // bell-curve envelope peaking at 40%. Softer bandpass center (800 Hz)
    // with subtle higher texture. Accelerating wingbeat suggests approach.

    private static func wingFlutter(sr: Double) -> [Float] {
        let dur: Float = 0.65
        let count = Int(Double(dur) * sr)
        var buf = [Float](repeating: 0, count: count)

        let pn = pinkNoise(count: count)
        let main = bandpass(pn, center: 800, q: 0.8, sr: sr)
        let hi   = bandpass(pn, center: 1800, q: 2.0, sr: sr)

        // Accelerating wingbeat (13→17 Hz — bird approaching)
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let n = t / dur

            let bell = exp(-pow((n - 0.4) / 0.22, 2))
            let wingRate: Float = 13.0 + 4.0 * n // accelerates
            let beatPhase = fmod(t * wingRate, 1.0)
            let beat = pow(max(0, sin(Float.pi * beatPhase)), 0.7)

            buf[i] = 0.035 * bell * beat * (main[i] + 0.3 * hi[i])
        }

        fade(&buf, fadeIn: Int(0.025 * sr), fadeOut: Int(0.04 * sr))
        return buf
    }

    // MARK: - 7b. Wing Departure (receding flight)
    //
    // A nightingale flying away — descending bandpass center (bird recedes
    // into distance), decelerating wingbeat, front-loaded envelope with
    // long tail. A low warm hum fades as the bird's presence retreats.

    private static func wingDeparture(sr: Double) -> [Float] {
        let dur: Float = 1.0
        let count = Int(Double(dur) * sr)
        var buf = [Float](repeating: 0, count: count)

        let pn = pinkNoise(count: count)

        // Descending bandpass — bird recedes into distance
        let blockSize = 512
        var pos = 0
        while pos < count {
            let end = min(pos + blockSize, count)
            let n = Float(pos) / Float(count)
            let center = Double(800.0 - 400.0 * n) // 800→400 Hz
            let block = Array(pn[pos..<end])
            let filtered = bandpass(block, center: center, q: 0.7, sr: sr)
            for j in 0..<filtered.count {
                buf[pos + j] = filtered[j]
            }
            pos = end
        }

        // Decelerating wingbeat (14→8 Hz — bird departing)
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let n = t / dur

            let env: Float
            if n < 0.12 {
                env = n / 0.12
            } else {
                env = exp(-(n - 0.12) / 0.3)
            }

            let wingRate = 14.0 - 6.0 * n
            let beatPhase = fmod(t * wingRate, 1.0)
            let beat = pow(max(0, sin(Float.pi * beatPhase)), 0.8)

            buf[i] *= 0.025 * env * beat
        }

        // Warm low hum that fades — the bird's presence receding
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let n = t / dur
            let env = (n < 0.08 ? n / 0.08 : 1.0) * exp(-n / 0.35)
            buf[i] += 0.006 * env * sin(twoPi * 170.0 * t)
        }

        fade(&buf, fadeIn: Int(0.02 * sr), fadeOut: Int(0.08 * sr))
        return buf
    }

    // MARK: - 8. Whisper Tone (breath with ghost pitch)
    //
    // An abstract whisper — formant-filtered pink noise with a barely
    // audible D4 ghost pitch (Shur finalis) adding subliminal warmth.
    // Softer formant centers, slower envelope, lower amplitude.

    private static func whisperTone(sr: Double) -> [Float] {
        let dur: Float = 2.0
        let count = Int(Double(dur) * sr)
        var buf = [Float](repeating: 0, count: count)

        let pn = pinkNoise(count: count)
        let f1 = bandpass(pn, center: 550,  q: 1.5, sr: sr)
        let f2 = bandpass(pn, center: 1100, q: 1.8, sr: sr)

        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let att = 1.0 - exp(-t / 0.2)
            let rel: Float = t > 0.7 ? exp(-(t - 0.7) / 0.7) : 1.0
            let env = att * rel
            buf[i] += 0.03 * env * (f1[i] + 0.4 * f2[i])
        }

        // Ghost pitch (D4 ~293.66 Hz, very quiet, AM-modulated)
        var ampMod = [Float](repeating: 0, count: count)
        for i in 0..<count { ampMod[i] = Float.random(in: -1...1) }
        lowpass(&ampMod, cutoff: 6, sr: sr)

        for i in 0..<count {
            let t = Float(i) / Float(sr)
            let env = (1.0 - exp(-t / 0.25)) * (t > 0.7 ? exp(-(t - 0.7) / 0.6) : 1.0)
            let am = 0.5 + 0.5 * ampMod[i]
            buf[i] += 0.007 * env * am * sin(twoPi * 293.66 * t)
        }

        fade(&buf, fadeIn: 16, fadeOut: Int(0.1 * sr))
        saturate(&buf, drive: 1.1)
        return buf
    }

    // MARK: - 9. Petal Whoosh (leaf-textured wind)
    //
    // Petals sweeping across the screen — broadband noise in the "leaf
    // band" (800-2000 Hz) with granular micro-bursts for rustling.
    // Softer than before, more organic shaping.

    private static func petalWhoosh(sr: Double) -> [Float] {
        let dur: Float = 0.7
        let count = Int(Double(dur) * sr)
        var buf = [Float](repeating: 0, count: count)

        // Leaf-band noise
        var wn = pinkNoise(count: count)
        lowpass(&wn, cutoff: 2000, sr: sr)
        let leafNoise = bandpass(wn, center: 1200, q: 0.7, sr: sr)

        for i in 0..<count {
            let n = Float(i) / Float(count)
            let env: Float
            if n < 0.2 {
                env = n / 0.2
            } else if n < 0.35 {
                env = 1.0
            } else {
                env = exp(-(n - 0.35) / 0.22)
            }
            buf[i] += 0.04 * env * leafNoise[i]
        }

        // Granular micro-bursts (leaf rustling texture)
        var pos = 0
        while pos < count {
            let gLen = Int(Double.random(in: 0.004...0.01) * sr)
            let gCenter = Double.random(in: 700...1800)
            let gAmp = Float.random(in: 0.003...0.009)
            let gap = Int(Double.random(in: 0.015...0.035) * sr)

            var grain = [Float](repeating: 0, count: gLen)
            for j in 0..<gLen {
                let w = 0.5 * (1.0 - cos(twoPi * Float(j) / Float(gLen)))
                grain[j] = w * Float.random(in: -1...1)
            }
            let fGrain = bandpass(grain, center: gCenter, q: 2.5, sr: sr)

            let gNorm = Float(pos) / Float(count)
            let posEnv: Float = gNorm < 0.15 ? gNorm / 0.15 : exp(-(gNorm - 0.15) / 0.3)
            for j in 0..<gLen where pos + j < count {
                buf[pos + j] += gAmp * posEnv * fGrain[j]
            }
            pos += gLen + gap
        }

        fade(&buf, fadeIn: Int(0.01 * sr), fadeOut: Int(0.035 * sr))
        return buf
    }

    // MARK: - 10. Gentle Tap (soft percussive touch)
    //
    // A fingertip touching glass or ceramic — brief, warm, round.
    // Lower frequency range, no onset click, pure sine decay.

    private static func gentleTap(sr: Double) -> [Float] {
        let count = Int(0.1 * sr)
        var buf = [Float](repeating: 0, count: count)

        // Short warm sine burst (~280 Hz)
        let freq = Float.random(in: 260...300)
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            buf[i] += 0.04 * exp(-t / 0.022) * sin(twoPi * freq * t)
        }

        // Slightly inharmonic second partial (subtle warmth)
        let freq2 = freq * Float.random(in: 2.4...2.7)
        for i in 0..<count {
            let t = Float(i) / Float(sr)
            buf[i] += 0.012 * exp(-t / 0.012) * sin(twoPi * freq2 * t)
        }

        fade(&buf, fadeIn: 2, fadeOut: Int(0.012 * sr))
        saturate(&buf, drive: 1.1)
        return buf
    }
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
