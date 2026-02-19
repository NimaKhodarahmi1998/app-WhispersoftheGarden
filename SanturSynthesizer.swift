//
//  SanturSynthesizer.swift
//  WhispersoftheGardenApp
//
//  Generative santur in Dastgah-e Shur — modeled after Payvar, Meshkatian, Kamkar.
//
//  Acoustic model: 4-string Karplus-Strong per voice, raised-cosine felt-mezrab
//  excitation, Weinreich double-decay, sympathetic resonance ghost voices,
//  velocity-dependent brightness, attack transient click.
//
//  Melodic model: 4-phase performance arc (daramad → ascending → owj → bazgasht),
//  gostaresh (gradual range expansion), question-answer phrase pairing,
//  pre-composed idiomatic Shur motifs with variation, proper forud cadences,
//  moteghayyer behavior, riz with messa di voce and swing, agogic accent,
//  progressive ritardando, and deep rubato.
//

import AVFoundation

final class SanturSynthesizer: @unchecked Sendable {

    var volume: Float = 0.5
    var isPlaying: Bool = false
    let sampleRate: Double

    // MARK: - Dastgah-e Shur in D — Measured Cents (Shafiei/Farhat)

    private let centsFromD4: [Double] = [
        -1200,  // 0: D3  — low bass drone
        -210,   // 1: C4  — aqaz (below finalis)
        0,      // 2: D4  — shahed / finalis
        137,    // 3: Ek4 — E koron (neutral 2nd, defines Shur)
        288,    // 4: F4
        486,    // 5: G4  — structural 4th
        626,    // 6: Ak4 — A koron (descending) / 700 = A natural (ascending)
        775,    // 7: Bb4
        980,    // 8: C5
        1200    // 9: D5  — upper octave
    ]
    private static let d4Hz: Double = 293.66
    private let aNaturalCents: Double = 700

    // MARK: - Motif Library

    // Closed motifs (end on degree 2 — resolution/answer phrases)
    private let closedMotifs: [[Int]] = [
        [1, 2, 3, 2, 1, 2],              // C-D-Ek-D-C-D
        [2, 3, 4, 3, 2],                  // D-Ek-F-Ek-D
        [2, 3, 4, 5, 4, 3, 2],            // Full lower tetrachord
        [4, 3, 2, 1, 2],                  // F descent to finalis
        [2, 3, 2, 1, 2],                  // Minimal ornamental
        [1, 2, 3, 4, 3, 2, 1, 2],         // Extended arch
        [2, 4, 3, 2],                      // Skip then step
        [3, 4, 3, 2, 1, 2],               // From Ek
        [2, 3, 4, 5, 6, 5, 4, 3, 2],      // Through Ak and back
        [2, 4, 5, 6, 5, 4, 3, 2],         // Skip then stepwise
        [5, 6, 7, 8, 7, 6, 5, 4, 3, 2],   // Full cascade from C5
    ]

    // Open motifs (end on non-finalis — question/tension phrases)
    private let openMotifs: [[Int]] = [
        [2, 3, 4, 5],                      // Ascending to G
        [2, 3, 4, 3, 4],                   // Oscillating on F
        [1, 2, 3, 4, 5, 6],               // Ascending to Ak
        [5, 6, 7, 6, 5],                   // Upper dwelling on G
        [4, 5, 6, 7, 8, 7, 6, 5],         // Extended upper reach
        [3, 4, 5, 6, 5, 4],               // Mid-range arch ending F
        [4, 5, 6, 7],                      // Rising to Bb
        [2, 3, 2, 3, 4],                   // Rocking then rise
        [3, 4, 5],                          // Short ascending
        [5, 4, 5, 6],                       // G area, rising
    ]

    // Forud motifs (cadential — always end on finalis)
    private let forudMotifs: [[Int]] = [
        [5, 4, 3, 2, 1, 2],               // Standard forud
        [7, 6, 5, 4, 3, 2],               // Long descent from Bb
        [4, 3, 2],                          // Short forud
        [8, 7, 6, 5, 4, 3, 2, 1, 2],      // Full cascade from C5
        [3, 2, 1, 2],                       // Minimal forud
        [6, 5, 4, 3, 2],                   // From Ak
    ]

    // Dwelling motifs (meditative oscillation)
    private let dwellingMotifs: [[Int]] = [
        [2, 3, 2, 3, 2],                   // D-Ek oscillation
        [5, 4, 5, 4, 5],                   // G-F oscillation
        [2, 1, 2, 1, 2],                   // D-C oscillation
        [4, 5, 4, 3, 4],                   // F-G-F-Ek-F
    ]

    // MARK: - Voices

    private var voices: [SanturVoice]
    private let voiceCount = 10

    // MARK: - Performance Arc

    private enum Phase: Int { case daramad, ascending, owj, bazgasht }

    private var performanceSamples: Int = 0
    private var cycleLength: Int

    private var performanceProgress: Double {
        Double(performanceSamples % cycleLength) / Double(cycleLength)
    }

    private var currentPhase: Phase {
        let p = performanceProgress
        if p < 0.35 { return .daramad }
        if p < 0.65 { return .ascending }
        if p < 0.75 { return .owj }
        return .bazgasht
    }

    /// Gostaresh: maximum scale degree available in current phase
    private var rangeCeiling: Int {
        let p = performanceProgress
        switch currentPhase {
        case .daramad:
            return p < 0.18 ? 4 : 5
        case .ascending:
            let phaseP = (p - 0.35) / 0.30
            return 5 + min(4, Int(phaseP * 5))
        case .owj:
            return 9
        case .bazgasht:
            let phaseP = (p - 0.75) / 0.25
            return max(4, 9 - Int(phaseP * 5))
        }
    }

    // MARK: - State Machine

    private enum State { case resting, phraseNote, graceWait, riz }

    private var state: State = .resting
    private var samplesUntilEvent: Int = 0

    // Phrase tracking
    private var currentMotif: [Int] = []
    private var motifIndex: Int = 0
    private var motifRepeatCount: Int = 0
    private var maxMotifRepeats: Int = 3
    private var phrasesSinceForud: Int = 0
    private var phrasesBeforeForud: Int = 4
    private var isForudPhrase: Bool = false
    private var lastPhraseEndedOnFinalis: Bool = true

    // Melodic context
    private var previousDegree: Int = 2
    private var lastDirection: Int = 0

    // Grace note
    private var graceMainFreq: Double = 0
    private var graceMainVel: Float = 0
    private var graceMainDegree: Int = 2

    // Riz
    private var rizStrikesLeft: Int = 0
    private var rizTotalStrikes: Int = 0
    private var rizFreq: Double = 0
    private var rizBaseVel: Float = 0
    private var rizStrikeNum: Int = 0

    init(sampleRate: Double) {
        self.sampleRate = sampleRate
        self.voices = (0..<10).map { _ in SanturVoice(sampleRate: sampleRate) }
        samplesUntilEvent = Int(Double.random(in: 1.0...2.0) * sampleRate)
        phrasesBeforeForud = Int.random(in: 3...6)
        cycleLength = Int(Double.random(in: 170...260) * sampleRate)
    }

    // MARK: - Frequency

    private func frequencyForDegree(_ degree: Int, ascending: Bool) -> Double {
        let d = max(0, min(9, degree))
        var cents = centsFromD4[d]
        if d == 6 && ascending { cents = aNaturalCents }
        cents += Double.random(in: -2...2)
        return SanturSynthesizer.d4Hz * pow(2.0, cents / 1200.0)
    }

    // MARK: - Render

    func render(frameCount: Int, output: UnsafeMutablePointer<Float>) {
        let vol = volume
        let playing = isPlaying

        for i in 0..<frameCount {
            if playing {
                performanceSamples += 1
                samplesUntilEvent -= 1
                if samplesUntilEvent <= 0 { handleEvent() }
            }
            var sample: Float = 0
            for v in 0..<voiceCount { sample += voices[v].tick() }
            output[i] = sample * vol
        }
    }

    // MARK: - Event Dispatch

    private func handleEvent() {
        switch state {
        case .resting:    beginPhrase()
        case .phraseNote: playNextNote()
        case .graceWait:  playMainAfterGrace()
        case .riz:        continueRiz()
        }
    }

    // MARK: - Phrase Generation

    private func beginPhrase() {
        phrasesSinceForud += 1
        let ceiling = rangeCeiling

        // Decide phrase type
        if phrasesSinceForud >= phrasesBeforeForud || !lastPhraseEndedOnFinalis {
            // Need resolution: forud or closed phrase
            if phrasesSinceForud >= phrasesBeforeForud {
                currentMotif = selectMotif(from: forudMotifs, ceiling: ceiling)
                isForudPhrase = true
                phrasesSinceForud = 0
                phrasesBeforeForud = Int.random(in: 3...6)
            } else {
                currentMotif = selectMotif(from: closedMotifs, ceiling: ceiling)
                isForudPhrase = false
            }
            motifRepeatCount = 0
            maxMotifRepeats = Int.random(in: 1...2)
        } else if motifRepeatCount < maxMotifRepeats && !currentMotif.isEmpty {
            // Repeat with variation (gostaresh: incremental expansion)
            currentMotif = varyMotif(currentMotif, ceiling: ceiling)
            motifRepeatCount += 1
            isForudPhrase = false
        } else {
            // New phrase — type depends on phase and question-answer balance
            isForudPhrase = false
            let phase = currentPhase

            if Double.random(in: 0...1) < 0.10 {
                currentMotif = selectMotif(from: dwellingMotifs, ceiling: ceiling)
            } else {
                switch phase {
                case .daramad:
                    // Mostly closed (contemplative), some open
                    currentMotif = Double.random(in: 0...1) < 0.65
                        ? selectMotif(from: closedMotifs, ceiling: ceiling)
                        : selectMotif(from: openMotifs, ceiling: ceiling)
                case .ascending:
                    // More open (building tension)
                    currentMotif = Double.random(in: 0...1) < 0.55
                        ? selectMotif(from: openMotifs, ceiling: ceiling)
                        : selectMotif(from: closedMotifs, ceiling: ceiling)
                case .owj:
                    // Mostly open (maximum tension), highest motifs
                    currentMotif = Double.random(in: 0...1) < 0.70
                        ? selectMotif(from: openMotifs, ceiling: ceiling)
                        : selectMotif(from: closedMotifs, ceiling: ceiling)
                case .bazgasht:
                    // Mostly closed/forud (resolving)
                    currentMotif = Double.random(in: 0...1) < 0.60
                        ? selectMotif(from: forudMotifs, ceiling: ceiling)
                        : selectMotif(from: closedMotifs, ceiling: ceiling)
                }
            }
            motifRepeatCount = 1
            maxMotifRepeats = Int.random(in: 2...4)
        }

        motifIndex = 0
        state = .phraseNote
        playNextNote()
    }

    private func selectMotif(from motifs: [[Int]], ceiling: Int) -> [Int] {
        // Filter by range ceiling and proximity to current register
        let inRange = motifs.filter { $0.allSatisfy { $0 <= ceiling } }
        let pool = inRange.isEmpty ? motifs : inRange
        let near = pool.filter { abs(($0.first ?? 2) - previousDegree) <= 3 }
        return (near.isEmpty ? pool : near).randomElement()!
    }

    private func varyMotif(_ motif: [Int], ceiling: Int) -> [Int] {
        var v = motif
        let r = Double.random(in: 0...1)
        if r < 0.18 && v.count > 3 {
            v = v.map { min(ceiling, $0 + 1) }
        } else if r < 0.30 && v.count > 3 {
            let peak = v.count / 2
            v.insert(min(ceiling, v[peak] + 1), at: peak + 1)
        } else if r < 0.42 && v.count > 4 {
            v.remove(at: Int.random(in: 1..<v.count - 1))
        } else if r < 0.65 {
            let idx = Int.random(in: 0..<v.count)
            v[idx] = max(0, min(ceiling, v[idx] + (Bool.random() ? 1 : -1)))
        }
        return v
    }

    // MARK: - Note Playing

    private func playNextNote() {
        guard motifIndex < currentMotif.count else {
            finishPhrase()
            return
        }

        let degree = currentMotif[motifIndex]
        let ascending = degree > previousDegree
            || (degree == previousDegree && lastDirection >= 0)
        let direction = degree > previousDegree ? 1
            : (degree < previousDegree ? -1 : lastDirection)

        let freq = frequencyForDegree(degree, ascending: ascending)
        let vel = phraseVelocity(degree: degree)

        // Grace note (~20%, not first/last)
        if Double.random(in: 0...1) < graceNoteProbability
            && motifIndex > 0 && motifIndex < currentMotif.count - 1
        {
            let gDeg = max(0, min(9, degree + (ascending ? 1 : -1)))
            strikeNote(frequency: frequencyForDegree(gDeg, ascending: ascending),
                       velocity: vel * 0.50)
            graceMainFreq = freq
            graceMainVel = vel
            graceMainDegree = degree
            state = .graceWait
            samplesUntilEvent = Int(Double.random(in: 0.045...0.075) * sampleRate)
            previousDegree = degree; lastDirection = direction; motifIndex += 1
            return
        }

        strikeNote(frequency: freq, velocity: vel)

        // Octave doubling (~10%)
        if Double.random(in: 0...1) < 0.10 && degree >= 2 && degree <= 7 {
            strikeNote(frequency: freq * 2.0, velocity: vel * 0.25)
        }

        previousDegree = degree; lastDirection = direction; motifIndex += 1

        // Riz on important notes near phrase end
        let isImportant = degree == 2 || degree == 5 || degree == 9
        if isImportant && Double.random(in: 0...1) < rizProbability
            && motifIndex >= currentMotif.count - 1
        {
            startRiz(freq: freq, vel: vel)
            return
        }

        if motifIndex < currentMotif.count {
            scheduleNextNote(currentDegree: degree)
        } else {
            finishPhrase()
        }
    }

    private func playMainAfterGrace() {
        strikeNote(frequency: graceMainFreq, velocity: graceMainVel)
        previousDegree = graceMainDegree
        state = .phraseNote
        motifIndex = min(motifIndex, currentMotif.count)
        if motifIndex < currentMotif.count {
            scheduleNextNote(currentDegree: graceMainDegree)
        } else {
            finishPhrase()
        }
    }

    private func finishPhrase() {
        state = .resting
        lastPhraseEndedOnFinalis = (currentMotif.last == 2)

        // Bass drone (~15%)
        if Double.random(in: 0...1) < 0.15 {
            strikeNote(frequency: frequencyForDegree(0, ascending: true),
                       velocity: Float.random(in: 0.08...0.14))
            // Sympathetic fifth (G3) with bass drone
            if Double.random(in: 0...1) < 0.40 {
                let g3freq = SanturSynthesizer.d4Hz * pow(2.0, (-1200.0 + 486.0) / 1200.0)
                strikeGhost(frequency: g3freq, velocity: 0.04)
            }
        }

        // "Sigh" note (~4%)
        if Double.random(in: 0...1) < 0.04 {
            let deg = [2, 5, 9].randomElement()!
            strikeNote(frequency: frequencyForDegree(deg, ascending: true),
                       velocity: Float.random(in: 0.28...0.36))
            samplesUntilEvent = withRubato(Double.random(in: 5.0...8.0))
        } else {
            // Rest duration varies by phase
            let rest: Double
            switch currentPhase {
            case .daramad:  rest = Double.random(in: 2.5...5.5)
            case .ascending: rest = Double.random(in: 1.5...3.5)
            case .owj:       rest = Double.random(in: 0.8...2.2)
            case .bazgasht:  rest = Double.random(in: 3.0...6.5)
            }
            // Longer after forud
            let multiplier = phrasesSinceForud == 0 ? 1.4 : 1.0
            samplesUntilEvent = withRubato(rest * multiplier)
        }
    }

    // MARK: - Phase-Dependent Parameters

    private var graceNoteProbability: Double {
        switch currentPhase {
        case .daramad: return 0.12
        case .ascending: return 0.20
        case .owj: return 0.28
        case .bazgasht: return 0.10
        }
    }

    private var rizProbability: Double {
        switch currentPhase {
        case .daramad: return 0.15
        case .ascending: return 0.10
        case .owj: return 0.20
        case .bazgasht: return 0.25
        }
    }

    private var phaseVelocityScale: Float {
        switch currentPhase {
        case .daramad: return 0.75
        case .ascending: return 0.90
        case .owj: return 1.15
        case .bazgasht: return 0.65
        }
    }

    // MARK: - Riz (Tremolo with Messa di Voce + Swing)

    private func startRiz(freq: Double, vel: Float) {
        state = .riz
        rizFreq = freq
        rizTotalStrikes = Int.random(in: 20...40)
        rizStrikesLeft = rizTotalStrikes
        rizBaseVel = vel * 0.55
        rizStrikeNum = 0
        // Slow start: first IOI is longer
        samplesUntilEvent = Int(Double.random(in: 0.10...0.14) * sampleRate)
    }

    private func continueRiz() {
        guard rizStrikesLeft > 0 else { return }

        let progress = Float(rizStrikeNum) / Float(max(1, rizTotalStrikes))

        // Messa di voce dynamics
        let vel: Float
        if progress < 0.20 {
            vel = rizBaseVel * (0.40 + 0.60 * (progress / 0.20))
        } else if progress < 0.60 {
            vel = rizBaseVel * Float.random(in: 0.93...1.07)
        } else {
            vel = rizBaseVel * (1.0 - (progress - 0.60) / 0.40 * 0.55)
        }

        strikeNote(frequency: rizFreq, velocity: max(vel, 0.025))
        rizStrikesLeft -= 1
        rizStrikeNum += 1

        if rizStrikesLeft > 0 {
            // Timing curve: slow start → peak speed → deceleration
            let baseIOI: Double
            if progress < 0.20 {
                baseIOI = Double.random(in: 0.10...0.14)
            } else if progress < 0.65 {
                baseIOI = Double.random(in: 0.080...0.110)
            } else {
                baseIOI = Double.random(in: 0.095...0.140)
            }
            // Swing: alternate slightly shorter and longer IOIs
            let swing = rizStrikeNum % 2 == 0 ? 0.95 : 1.05
            let jitter = Double.random(in: -0.006...0.006)
            samplesUntilEvent = max(1, Int((baseIOI * swing + jitter) * sampleRate))
        } else {
            state = .resting
            // Post-riz silence (contemplative)
            samplesUntilEvent = withRubato(Double.random(in: 2.5...5.0))
        }
    }

    // MARK: - Dynamics

    private func phraseVelocity(degree: Int) -> Float {
        let total = max(Float(currentMotif.count), 1)
        let pos = Float(motifIndex)
        let norm = pos / max(total - 1, 1)

        // Arch peaking at ~40-50%
        let arch = sin(Float.pi * min(norm / 0.85, 1.0))
        let base: Float = 0.06
        let peak: Float = 0.24
        var vel = base + (peak - base) * arch

        // Higher degrees slightly louder
        vel += Float(max(0, degree - 2)) * 0.010

        // Phase scaling
        vel *= phaseVelocityScale

        // Forud decrescendo
        if isForudPhrase && norm > 0.4 {
            vel *= 1.0 - (norm - 0.4) * 0.6
        }

        return max(vel * Float.random(in: 0.88...1.12), 0.025)
    }

    // MARK: - Timing

    private func scheduleNextNote(currentDegree: Int) {
        let remaining = currentMotif.count - motifIndex
        var delay: Double

        if remaining <= 1 {
            delay = Double.random(in: 0.55...1.1)
        } else if lastDirection > 0 {
            delay = Double.random(in: 0.22...0.48)
        } else if lastDirection < 0 {
            delay = Double.random(in: 0.38...0.80)
        } else {
            delay = Double.random(in: 0.28...0.60)
        }

        // Agogic accent: important notes held longer
        if currentDegree == 2 && Double.random(in: 0...1) < 0.35 {
            delay *= 1.5
        } else if currentDegree == 5 && Double.random(in: 0...1) < 0.25 {
            delay *= 1.3
        } else if currentDegree == 6 && Double.random(in: 0...1) < 0.20 {
            delay *= 1.25
        }

        // Progressive forud ritardando (last 4 notes slow progressively)
        if isForudPhrase && remaining <= 4 {
            let ritMultipliers = [2.0, 1.6, 1.35, 1.15]
            delay *= ritMultipliers[min(remaining, 3)]
        }

        samplesUntilEvent = withRubato(delay)
    }

    private func withRubato(_ s: Double) -> Int {
        Int(s * Double.random(in: 0.65...1.35) * sampleRate)
    }

    // MARK: - Voice Management

    private func strikeNote(frequency: Double, velocity: Float) {
        // Allocate quietest voice
        var quietest = 0
        var lowest: Float = .infinity
        for i in 0..<voiceCount {
            let e = voices[i].energy
            if e < lowest { lowest = e; quietest = i }
        }
        voices[quietest].strike(frequency: frequency, velocity: velocity)

        // Sympathetic resonance — ghost voices at octave and fifth
        if velocity > 0.06 {
            if frequency > 200 {
                strikeGhost(frequency: frequency / 2.0, velocity: velocity * 0.030)
            }
            strikeGhost(frequency: frequency * 1.498, velocity: velocity * 0.018)
        }
    }

    private func strikeGhost(frequency: Double, velocity: Float) {
        var quietest = 0
        var lowest: Float = .infinity
        for i in 0..<voiceCount {
            let e = voices[i].energy
            if e < lowest { lowest = e; quietest = i }
        }
        // Only use truly silent voices for ghosts
        if lowest < 0.01 {
            voices[quietest].strike(frequency: frequency, velocity: velocity)
        }
    }
}

// MARK: - Santur Voice (4-String Course)

private final class SanturVoice {

    private let sampleRate: Double
    private let stringCount = 4

    private var delayLines: [[Float]]
    private var activeLens: [Int]
    private var writeIndices: [Int]

    private let stringWeights: [Float] = [0.82, 1.0, 0.93, 0.72]
    private let weightSum: Float = 3.47

    private var active: Bool = false

    // Two-stage Weinreich decay
    private var samplesSinceStrike: Int = 0
    private var gPrompt: Float = 0
    private var gAftersound: Float = 0
    private var crossoverSamples: Int = 0

    // Frequency-dependent loop filter
    private var filterA: Float = 0.55

    private(set) var energy: Float = 0
    private let energyThreshold: Float = 0.00012

    init(sampleRate: Double) {
        self.sampleRate = sampleRate
        let maxLen = Int(sampleRate / 100) + 4
        delayLines = (0..<4).map { _ in [Float](repeating: 0, count: maxLen) }
        activeLens = [Int](repeating: 0, count: 4)
        writeIndices = [Int](repeating: 0, count: 4)
    }

    func strike(frequency: Double, velocity: Float) {
        let baseLen = Int(sampleRate / frequency)
        guard baseLen > 1, baseLen < delayLines[0].count else { return }

        // Frequency-dependent detuning (research: wider spread for higher notes)
        let detuneCents: [Double]
        if frequency > 500 {
            detuneCents = [0.0, 0.7, 1.4, 2.4]
        } else if frequency > 300 {
            detuneCents = [0.0, 0.5, 1.1, 1.9]
        } else {
            detuneCents = [0.0, 0.4, 0.8, 1.5]
        }

        for s in 0..<stringCount {
            let ratio = pow(2.0, detuneCents[s] / 1200.0)
            let len = max(2, min(Int(sampleRate / (frequency * ratio)),
                                 delayLines[s].count - 1))
            activeLens[s] = len

            for idx in 0..<len { delayLines[s][idx] = 0 }

            // Phase randomization: each string starts at slightly different offset
            let onsetJitter = Int.random(in: 0...min(16, len / 4))

            // Raised cosine (Hann) excitation — felt-tipped mezrab
            let hammerWidth = max(2, len / 8)
            let startPos = len / 7 + Int.random(in: -1...1)

            // Velocity-dependent brightness: harder = brighter
            let feltLP = 0.38 + velocity * 0.30

            var prev: Float = 0
            for j in 0..<hammerWidth {
                let window = 0.5 * (1.0 - cos(2.0 * Float.pi * Float(j)
                                               / Float(hammerWidth)))
                let noise = Float.random(in: -1...1)
                prev = feltLP * noise + (1.0 - feltLP) * prev
                let pos = (startPos + j + onsetJitter) % len
                delayLines[s][pos] = prev * window * velocity * stringWeights[s]
            }

            // Attack transient click (brief unfiltered noise, models hammer contact)
            let clickLen = min(4, hammerWidth / 3)
            for j in 0..<clickLen {
                let pos = (startPos - 2 + j + len) % len
                delayLines[s][pos] += Float.random(in: -1...1) * velocity * 0.15
                    * stringWeights[s]
            }

            writeIndices[s] = 0
        }

        // Frequency-dependent decay
        if frequency > 500 {
            gPrompt = 0.9968; gAftersound = 0.9994
            crossoverSamples = Int(0.35 * sampleRate)
            filterA = 0.58
        } else if frequency > 300 {
            gPrompt = 0.9977; gAftersound = 0.9997
            crossoverSamples = Int(0.6 * sampleRate)
            filterA = 0.54
        } else {
            gPrompt = 0.9983; gAftersound = 0.9998
            crossoverSamples = Int(0.95 * sampleRate)
            filterA = 0.52
        }

        samplesSinceStrike = 0
        active = true
        energy = velocity
    }

    func tick() -> Float {
        guard active else { return 0 }

        samplesSinceStrike += 1

        let alpha = min(1.0, Float(samplesSinceStrike)
                        / Float(max(1, crossoverSamples)))
        let g = gPrompt + alpha * (gAftersound - gPrompt)

        var output: Float = 0

        for s in 0..<stringCount {
            let len = activeLens[s]
            guard len > 1 else { continue }

            let readIdx = writeIndices[s]
            let nextIdx = (readIdx + 1) % len
            let current = delayLines[s][readIdx]

            // Asymmetric loop filter (frequency-dependent coefficient)
            let filtered = filterA * delayLines[s][readIdx]
                + (1.0 - filterA) * delayLines[s][nextIdx]

            delayLines[s][readIdx] = filtered * g
            writeIndices[s] = nextIdx
            output += current * stringWeights[s]
        }

        output /= weightSum
        energy = energy * 0.9995 + abs(output) * 0.0005

        if energy < energyThreshold {
            active = false
            energy = 0
        }

        return output
    }
}
