//
//  SanturSynthesizer.swift
//  WhispersoftheGardenApp
//
//  Generative santur in Dastgah-e Shur — gusheh-based composition engine
//  modeled after Payvar, Meshkatian, Kamkar.
//
//  Melodic model: 7-gusheh Markov navigation (Daramad, Kereshmeh, Salmak,
//  Shahnaz, Hosseini, Dobeyti, Qoraei), context-dependent intonation,
//  6 ornament types, 4 riz styles, moteghayyer deflection, phrase intelligence.
//
//  Acoustic model: 4-string Karplus-Strong per voice, raised-cosine felt-mezrab
//  excitation, Weinreich double-decay, sympathetic resonance ghost voices,
//  velocity-dependent brightness, attack transient click.
//

import AVFoundation

final class SanturSynthesizer: @unchecked Sendable {

    var volume: Float = 0.5
    var isPlaying: Bool = false
    let sampleRate: Double

    // MARK: - Dastgah-e Shur in D — Measured Cents (Shafiei/Farhat)

    private let centsFromD4: [Double] = [
        -1200, -210, 0, 137, 288, 486, 626, 775, 980, 1200
    ]
    private static let d4Hz: Double = 293.66
    private let aNaturalCents: Double = 700

    // MARK: - Types

    private enum MoteghayyerState { case koron, natural, deflecting }
    private enum RizType { case nimRiz, kamel, shetabi, kandi }
    private enum OrnamentType { case grace, doubleGrace, tahrir, eshare, dorrab, cascade }

    private enum State {
        case resting, phraseNote, graceWait, doubleGrace
        case tahrir, dorrab, cascade, eshareWait, riz
    }

    private struct GushehData {
        let shahed: Int, rangeLow: Int, rangeHigh: Int, usesNatural: Bool
        let intensity: Float, brightness: Float
        let motifs: [[Int]], foruds: [[Int]], dwellings: [[Int]]
        let transitions: [(Int, Double)]
    }

    // MARK: - Gusheh Data

    private let gushehs: [GushehData]

    private static func buildGushehs() -> [GushehData] {
        [
            // 0: Daramad — opening, contemplative, shahed D4
            GushehData(shahed: 2, rangeLow: 1, rangeHigh: 5, usesNatural: false,
                       intensity: 0.30, brightness: 0.30,
                       motifs: [[2,3,2,1,2],[1,2,3,2],[2,3,4,3,2],[2,1,2,3,2],
                                [2,3,4,5,4,3,2],[1,2,3,4,3,2,1,2],[2,4,3,2],[3,4,3,2,1,2]],
                       foruds: [[4,3,2,1,2],[5,4,3,2,1,2],[3,2,1,2]],
                       dwellings: [[2,3,2,3,2],[2,1,2,1,2]],
                       transitions: [(1,0.30),(2,0.25),(3,0.10),(5,0.15),(6,0.15),(0,0.05)]),
            // 1: Kereshmeh — rhythmic, playful, shahed D4
            GushehData(shahed: 2, rangeLow: 1, rangeHigh: 5, usesNatural: false,
                       intensity: 0.35, brightness: 0.35,
                       motifs: [[2,3,2,3,4,3,2],[2,4,2,4,3,2],[2,3,4,2,3,4,3,2],
                                [1,2,3,2,1,2,3,2],[2,3,2,4,3,2]],
                       foruds: [[4,3,2,1,2],[3,2,1,2]],
                       dwellings: [[2,3,2,3,2,3,2]],
                       transitions: [(0,0.20),(2,0.35),(3,0.15),(5,0.15),(6,0.10),(1,0.05)]),
            // 2: Salmak — transitional, shahed F4
            GushehData(shahed: 4, rangeLow: 2, rangeHigh: 6, usesNatural: false,
                       intensity: 0.45, brightness: 0.40,
                       motifs: [[4,5,6,5,4],[2,3,4,5,4],[4,5,4,3,4],
                                [3,4,5,6,5,4,3],[4,3,4,5,6,5,4],[4,5,6,5,4,3,2]],
                       foruds: [[5,4,3,2,1,2],[4,3,2],[6,5,4,3,2]],
                       dwellings: [[4,5,4,5,4]],
                       transitions: [(3,0.40),(4,0.15),(0,0.15),(5,0.15),(1,0.10),(2,0.05)]),
            // 3: Shahnaz — bright, shahed G4, A NATURAL
            GushehData(shahed: 5, rangeLow: 4, rangeHigh: 8, usesNatural: true,
                       intensity: 0.60, brightness: 0.60,
                       motifs: [[5,6,7,6,5],[4,5,6,7,6,5],[5,6,7,8,7,6,5],
                                [5,6,5,4,5],[6,7,8,7,6,5],[5,7,6,5],
                                [4,5,6,7,8,7,6,5,4]],
                       foruds: [[7,6,5,4,3,2],[6,5,4,3,2],[8,7,6,5,4,3,2,1,2]],
                       dwellings: [[5,6,5,6,5]],
                       transitions: [(4,0.35),(2,0.15),(5,0.20),(0,0.15),(6,0.10),(3,0.05)]),
            // 4: Hosseini — climactic, shahed Bb4, A NATURAL
            GushehData(shahed: 7, rangeLow: 5, rangeHigh: 9, usesNatural: true,
                       intensity: 0.80, brightness: 0.80,
                       motifs: [[7,8,9,8,7],[5,6,7,8,9,8,7],[7,8,7,6,7],
                                [6,7,8,9,8,7,6],[7,9,8,7],[8,9,8,7,6,7]],
                       foruds: [[9,8,7,6,5,4,3,2],[8,7,6,5,4,3,2,1,2],[7,6,5,4,3,2]],
                       dwellings: [[7,8,7,8,7]],
                       transitions: [(3,0.20),(5,0.25),(0,0.20),(2,0.15),(6,0.15),(4,0.05)]),
            // 5: Dobeyti — lyrical, shahed F4, koron
            GushehData(shahed: 4, rangeLow: 1, rangeHigh: 6, usesNatural: false,
                       intensity: 0.40, brightness: 0.35,
                       motifs: [[4,5,4,3,2,3,4],[2,3,4,5,6,5,4],[4,3,2,3,4,5,4],
                                [4,6,5,4,3,4],[1,2,3,4,5,4,3],[4,5,6,5,4,3]],
                       foruds: [[5,4,3,2,1,2],[6,5,4,3,2],[4,3,2]],
                       dwellings: [[4,3,4,3,4]],
                       transitions: [(0,0.30),(6,0.25),(2,0.15),(1,0.15),(3,0.10),(5,0.05)]),
            // 6: Qoraei — low, contemplative, shahed Ek4
            GushehData(shahed: 3, rangeLow: 1, rangeHigh: 4, usesNatural: false,
                       intensity: 0.25, brightness: 0.25,
                       motifs: [[3,2,1,2,3],[1,2,3,4,3,2],[3,4,3,2,3],
                                [2,3,4,3,2,1,2],[3,2,3,4,3],[1,2,3,2,1,2,3]],
                       foruds: [[4,3,2,1,2],[3,2,1,2]],
                       dwellings: [[3,2,3,2,3]],
                       transitions: [(0,0.45),(1,0.20),(2,0.15),(5,0.15),(6,0.05)]),
        ]
    }

    // MARK: - Voices

    private var voices: [SanturVoice]
    private let voiceCount = 10

    // MARK: - Navigation State

    private var currentGushehIdx: Int = 0
    private var phrasesInGusheh: Int = 0
    private var gushehPhraseTarget: Int = 5
    private var totalPhrases: Int = 0
    private var journeyPhraseLimit: Int = 40
    private var gushehVisitCounts: [Int]
    private var currentMoteghayyer: MoteghayyerState = .koron
    private var deflectionPhrasesLeft: Int = 0
    private var pendingGushehTransition: Bool = false
    private var journeyResetPending: Bool = false
    private var flickerNextDeg6: Bool = false

    // MARK: - State Machine

    private var state: State = .resting
    private var samplesUntilEvent: Int = 0
    private var performanceSamples: Int = 0

    // Phrase tracking
    private var currentMotif: [Int] = []
    private var motifIndex: Int = 0
    private var motifRepeatCount: Int = 0
    private var maxMotifRepeats: Int = 3
    private var phrasesSinceForud: Int = 0
    private var phrasesBeforeForud: Int = 4
    private var isForudPhrase: Bool = false
    private var lastPhraseEndedOnFinalis: Bool = true
    private var lastPhraseOpen: Bool = false
    private var lastPhraseLength: Int = 4
    private var consecutiveShahedDwells: Int = 0
    private var phraseHashes: [UInt64] = [0, 0, 0, 0, 0]
    private var phraseHashIdx: Int = 0

    // Melodic context
    private var previousDegree: Int = 2
    private var lastDirection: Int = 0

    // Grace note
    private var graceMainFreq: Double = 0
    private var graceMainVel: Float = 0
    private var graceMainDegree: Int = 2

    // Double grace
    private var dgPhase: Int = 0
    private var dgMainFreq: Double = 0
    private var dgUpperFreq: Double = 0
    private var dgLowerFreq: Double = 0
    private var dgVel: Float = 0
    private var dgMainDegree: Int = 2

    // Tahrir
    private var tahrirCount: Int = 0
    private var tahrirTotal: Int = 0
    private var tahrirMainFreq: Double = 0
    private var tahrirUpperFreq: Double = 0
    private var tahrirVel: Float = 0
    private var tahrirOnMain: Bool = true

    // Dorrab
    private var dorrabCount: Int = 0
    private var dorrabTotal: Int = 0
    private var dorrabFreq: Double = 0
    private var dorrabVel: Float = 0

    // Cascade
    private var cascadeDegrees: [Int] = []
    private var cascadeIdx: Int = 0
    private var cascadeVel: Float = 0

    // Eshare
    private var eshareMainFreq: Double = 0
    private var eshareMainVel: Float = 0
    private var eshareMainDegree: Int = 2

    // Riz
    private var rizStrikesLeft: Int = 0
    private var rizTotalStrikes: Int = 0
    private var rizFreq: Double = 0
    private var rizBaseVel: Float = 0
    private var rizStrikeNum: Int = 0
    private var rizType: RizType = .kamel

    // MARK: - Init

    init(sampleRate: Double) {
        self.sampleRate = sampleRate
        self.voices = (0..<10).map { _ in SanturVoice(sampleRate: sampleRate) }
        self.gushehs = SanturSynthesizer.buildGushehs()
        self.gushehVisitCounts = [Int](repeating: 0, count: 7)
        samplesUntilEvent = Int(Double.random(in: 1.0...2.0) * sampleRate)
        phrasesBeforeForud = Int.random(in: 3...6)
        journeyPhraseLimit = Int.random(in: 35...50)
        gushehPhraseTarget = Int.random(in: 4...8)
        currentMotif.reserveCapacity(16)
        cascadeDegrees.reserveCapacity(8)
    }

    // MARK: - Context-Dependent Intonation

    private func frequencyForDegree(_ degree: Int, ascending: Bool) -> Double {
        let d = max(0, min(9, degree))
        var cents = centsFromD4[d]
        if d == 6 {
            if flickerNextDeg6 || currentMoteghayyer == .natural
                || (currentMoteghayyer == .deflecting && ascending) {
                cents = aNaturalCents
                flickerNextDeg6 = false
            }
        }
        switch d {
        case 3:  cents += ascending ? Double.random(in: 0...8) : Double.random(in: -12...0)
        case 6:
            if currentMoteghayyer == .natural { cents += Double.random(in: -3...5) }
            else { cents += ascending ? Double.random(in: -3...8) : Double.random(in: -11...0) }
        case 7:  cents += ascending ? Double.random(in: -5...5) : Double.random(in: -10...3)
        default: cents += Double.random(in: -2...2)
        }
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
        case .resting:     beginPhrase()
        case .phraseNote:  playNextNote()
        case .graceWait:   playMainAfterGrace()
        case .doubleGrace: continueDoubleGrace()
        case .tahrir:      continueTahrir()
        case .dorrab:      continueDorrab()
        case .cascade:     continueCascade()
        case .eshareWait:  playMainAfterEshare()
        case .riz:         continueRiz()
        }
    }

    // MARK: - Gusheh Navigation

    private func shouldTransitionGusheh() -> Bool {
        if phrasesInGusheh < 3 { return false }
        if phrasesInGusheh >= gushehPhraseTarget { return true }
        let excess = Double(phrasesInGusheh - 3) / Double(max(1, gushehPhraseTarget - 3))
        return Double.random(in: 0...1) < excess * 0.4
    }

    private func transitionGusheh() {
        let current = gushehs[currentGushehIdx]
        var candidates = current.transitions
        for i in 0..<candidates.count {
            let (target, weight) = candidates[i]
            if gushehVisitCounts[target] >= 3 { candidates[i] = (target, weight * 0.5) }
        }
        let totalWeight = candidates.reduce(0.0) { $0 + $1.1 }
        var roll = Double.random(in: 0..<max(totalWeight, 0.01))
        var nextIdx = candidates[0].0
        for (idx, weight) in candidates {
            roll -= weight
            if roll <= 0 { nextIdx = idx; break }
        }
        let wasNatural = current.usesNatural
        let nextGusheh = gushehs[nextIdx]
        if wasNatural && !nextGusheh.usesNatural {
            currentMoteghayyer = .deflecting
            deflectionPhrasesLeft = 1
        } else {
            currentMoteghayyer = nextGusheh.usesNatural ? .natural : .koron
        }
        gushehVisitCounts[nextIdx] += 1
        currentGushehIdx = nextIdx
        phrasesInGusheh = 0
        gushehPhraseTarget = Int.random(in: 4...8)
    }

    private func resetJourney() {
        currentGushehIdx = 0
        phrasesInGusheh = 0
        totalPhrases = 0
        for i in 0..<7 { gushehVisitCounts[i] = 0 }
        currentMoteghayyer = .koron
        deflectionPhrasesLeft = 0
        journeyPhraseLimit = Int.random(in: 35...50)
        gushehPhraseTarget = Int.random(in: 4...8)
        phrasesSinceForud = 0
        phrasesBeforeForud = Int.random(in: 3...6)
        journeyResetPending = false
    }

    // MARK: - Phrase Generation

    private func beginPhrase() {
        if journeyResetPending { resetJourney() }
        totalPhrases += 1
        phrasesInGusheh += 1
        phrasesSinceForud += 1
        if currentMoteghayyer == .deflecting {
            deflectionPhrasesLeft -= 1
            if deflectionPhrasesLeft <= 0 { currentMoteghayyer = .koron }
        }
        if totalPhrases >= journeyPhraseLimit {
            buildElevatedForud()
            journeyResetPending = true
            return
        }
        if pendingGushehTransition {
            transitionGusheh()
            pendingGushehTransition = false
        }
        if shouldTransitionGusheh() {
            let g = gushehs[currentGushehIdx]
            currentMotif = selectMotif(from: g.foruds, gusheh: g)
            isForudPhrase = true
            phrasesSinceForud = 0
            phrasesBeforeForud = Int.random(in: 3...6)
            pendingGushehTransition = true
        } else {
            selectPhraseForCurrentGusheh()
        }
        let hash = motifHash(currentMotif)
        phraseHashes[phraseHashIdx % 5] = hash
        phraseHashIdx += 1
        motifIndex = 0
        state = .phraseNote
        if trySurpriseEvent() { return }
        playNextNote()
    }

    private func selectPhraseForCurrentGusheh() {
        let g = gushehs[currentGushehIdx]
        if phrasesSinceForud >= phrasesBeforeForud {
            currentMotif = selectMotif(from: g.foruds, gusheh: g)
            isForudPhrase = true
            phrasesSinceForud = 0
            phrasesBeforeForud = Int.random(in: 3...6)
            motifRepeatCount = 0; maxMotifRepeats = Int.random(in: 1...2)
            lastPhraseOpen = false; lastPhraseLength = currentMotif.count
            return
        }
        if Double.random(in: 0...1) < 0.08 && !g.dwellings.isEmpty {
            consecutiveShahedDwells += 1
            if consecutiveShahedDwells <= Int.random(in: 3...5) {
                currentMotif = selectMotif(from: g.dwellings, gusheh: g)
                isForudPhrase = false; motifRepeatCount = 0; maxMotifRepeats = 1
                lastPhraseOpen = false; lastPhraseLength = currentMotif.count
                return
            }
        }
        consecutiveShahedDwells = 0
        isForudPhrase = false
        if motifRepeatCount < maxMotifRepeats && !currentMotif.isEmpty
            && Double.random(in: 0...1) < 0.45 {
            currentMotif = varyMotif(currentMotif, gusheh: g)
            motifRepeatCount += 1
        } else {
            if lastPhraseOpen && Double.random(in: 0...1) < 0.55 {
                currentMotif = selectMotif(from: g.foruds, gusheh: g)
                lastPhraseOpen = false
            } else {
                var candidate = selectMotif(from: g.motifs, gusheh: g)
                for _ in 0..<3 {
                    if abs(candidate.count - lastPhraseLength) >= 2 { break }
                    candidate = selectMotif(from: g.motifs, gusheh: g)
                }
                let h = motifHash(candidate)
                var isRepeat = false
                for i in 0..<5 { if phraseHashes[i] == h { isRepeat = true; break } }
                if isRepeat { candidate = varyMotif(candidate, gusheh: g) }
                currentMotif = candidate
                let lastDeg = candidate.last ?? g.shahed
                lastPhraseOpen = (lastDeg != 2 && lastDeg != g.shahed)
            }
            motifRepeatCount = 1; maxMotifRepeats = Int.random(in: 2...4)
        }
        lastPhraseLength = currentMotif.count
        lastPhraseEndedOnFinalis = (currentMotif.last == 2)
    }

    private func buildElevatedForud() {
        let g = gushehs[currentGushehIdx]
        var motif: [Int] = []
        for d in stride(from: g.rangeHigh, through: 1, by: -1) { motif.append(d) }
        motif.append(2)
        currentMotif = motif
        isForudPhrase = true
        motifIndex = 0
        state = .phraseNote
        playNextNote()
    }

    private func selectMotif(from motifs: [[Int]], gusheh: GushehData) -> [Int] {
        let inRange = motifs.filter {
            $0.allSatisfy { $0 >= gusheh.rangeLow && $0 <= gusheh.rangeHigh }
        }
        let pool = inRange.isEmpty ? motifs : inRange
        let near = pool.filter { abs(($0.first ?? 2) - previousDegree) <= 3 }
        return (near.isEmpty ? pool : near).randomElement()!
    }

    private func varyMotif(_ motif: [Int], gusheh: GushehData) -> [Int] {
        var v = motif
        let r = Double.random(in: 0...1)
        let lo = gusheh.rangeLow, hi = gusheh.rangeHigh
        if r < 0.18 && v.count > 3 {
            v = v.map { max(lo, min(hi, $0 + 1)) }
        } else if r < 0.30 && v.count > 3 {
            let peak = v.count / 2
            v.insert(min(hi, v[peak] + 1), at: peak + 1)
        } else if r < 0.42 && v.count > 4 {
            v.remove(at: Int.random(in: 1..<v.count - 1))
        } else if r < 0.65 {
            let idx = Int.random(in: 0..<v.count)
            v[idx] = max(lo, min(hi, v[idx] + (Bool.random() ? 1 : -1)))
        }
        return v
    }

    private func motifHash(_ motif: [Int]) -> UInt64 {
        var h: UInt64 = 5381
        for d in motif { h = h &* 33 &+ UInt64(d) }
        return h
    }

    // MARK: - Surprise Events

    private func trySurpriseEvent() -> Bool {
        let roll = Double.random(in: 0...1)
        if roll < 0.05 {
            state = .resting
            samplesUntilEvent = Int(Double.random(in: 6.0...12.0) * sampleRate)
            return true
        }
        if roll < 0.09 && currentMotif.count > 4 {
            let cutPoint = currentMotif.count / 2
            currentMotif = Array(currentMotif[0..<cutPoint]) + [3, 2, 1, 2]
            return false
        }
        if roll < 0.12 {
            currentMotif.insert(9, at: 0)
            return false
        }
        if roll < 0.16 && currentMoteghayyer == .koron {
            flickerNextDeg6 = true
            currentMotif.insert(6, at: 0)
            return false
        }
        if roll < 0.19 {
            let g = gushehs[currentGushehIdx]
            let count = Int.random(in: 4...8)
            currentMotif = (0..<count).map { _ in
                max(g.rangeLow, min(g.rangeHigh, g.shahed + Int.random(in: -1...1)))
            }
            return false
        }
        return false
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
        let vel = gushehVelocity(degree: degree)

        let ornProb = 0.12 + Double(gushehs[currentGushehIdx].intensity) * 0.22
        if Double.random(in: 0...1) < ornProb
            && motifIndex > 0 && motifIndex < currentMotif.count - 1 {
            let ornType = selectOrnament()
            switch ornType {
            case .grace:       startGraceNote(degree: degree, freq: freq, vel: vel, ascending: ascending)
            case .doubleGrace: startDoubleGrace(degree: degree, freq: freq, vel: vel)
            case .tahrir:      startTahrir(degree: degree, freq: freq, vel: vel)
            case .eshare:      startEshare(degree: degree, freq: freq, vel: vel)
            case .dorrab:      startDorrab(freq: freq, vel: vel)
            case .cascade:     startCascade(degree: degree, vel: vel)
            }
            previousDegree = degree; lastDirection = direction; motifIndex += 1
            return
        }

        strikeNote(frequency: freq, velocity: vel)
        if Double.random(in: 0...1) < 0.08 && degree >= 2 && degree <= 7 {
            strikeNote(frequency: freq * 2.0, velocity: vel * 0.22)
        }
        previousDegree = degree; lastDirection = direction; motifIndex += 1

        let g = gushehs[currentGushehIdx]
        let isImportant = degree == g.shahed || degree == 2 || degree == 9
        let rizProb = 0.10 + Double(g.intensity) * 0.15
        if isImportant && Double.random(in: 0...1) < rizProb
            && motifIndex >= currentMotif.count - 1 {
            startRiz(freq: freq, vel: vel)
            return
        }
        if motifIndex < currentMotif.count {
            scheduleNextNote(currentDegree: degree)
        } else {
            finishPhrase()
        }
    }

    private func selectOrnament() -> OrnamentType {
        let roll = Double.random(in: 0..<100)
        if roll < 35 { return .grace }
        if roll < 55 { return .doubleGrace }
        if roll < 70 { return .tahrir }
        if roll < 80 { return .eshare }
        if roll < 92 { return .dorrab }
        return .cascade
    }

    // MARK: - Grace Note

    private func startGraceNote(degree: Int, freq: Double, vel: Float, ascending: Bool) {
        let gDeg = max(0, min(9, degree + (ascending ? 1 : -1)))
        strikeNote(frequency: frequencyForDegree(gDeg, ascending: ascending),
                   velocity: vel * 0.50)
        graceMainFreq = freq; graceMainVel = vel; graceMainDegree = degree
        state = .graceWait
        samplesUntilEvent = Int(Double.random(in: 0.045...0.075) * sampleRate)
    }

    private func playMainAfterGrace() {
        strikeNote(frequency: graceMainFreq, velocity: graceMainVel)
        previousDegree = graceMainDegree
        state = .phraseNote
        if motifIndex < currentMotif.count {
            scheduleNextNote(currentDegree: graceMainDegree)
        } else { finishPhrase() }
    }

    // MARK: - Double Grace (turn: upper-lower-main)

    private func startDoubleGrace(degree: Int, freq: Double, vel: Float) {
        let upper = max(0, min(9, degree + 1))
        let lower = max(0, min(9, degree - 1))
        dgUpperFreq = frequencyForDegree(upper, ascending: true)
        dgLowerFreq = frequencyForDegree(lower, ascending: false)
        dgMainFreq = freq; dgVel = vel; dgMainDegree = degree; dgPhase = 0
        strikeNote(frequency: dgUpperFreq, velocity: vel * 0.40)
        state = .doubleGrace
        samplesUntilEvent = Int(Double.random(in: 0.040...0.065) * sampleRate)
    }

    private func continueDoubleGrace() {
        dgPhase += 1
        if dgPhase == 1 {
            strikeNote(frequency: dgLowerFreq, velocity: dgVel * 0.35)
            samplesUntilEvent = Int(Double.random(in: 0.040...0.065) * sampleRate)
        } else {
            strikeNote(frequency: dgMainFreq, velocity: dgVel)
            previousDegree = dgMainDegree
            state = .phraseNote
            if motifIndex < currentMotif.count {
                scheduleNextNote(currentDegree: dgMainDegree)
            } else { finishPhrase() }
        }
    }

    // MARK: - Tahrir (rapid alternation main<->upper)

    private func startTahrir(degree: Int, freq: Double, vel: Float) {
        let upper = max(0, min(9, degree + 1))
        tahrirMainFreq = freq
        tahrirUpperFreq = frequencyForDegree(upper, ascending: true)
        tahrirVel = vel
        tahrirTotal = Int.random(in: 3...5) * 2
        tahrirCount = 0; tahrirOnMain = true
        strikeNote(frequency: freq, velocity: vel * 0.55)
        state = .tahrir
        samplesUntilEvent = Int(Double.random(in: 0.060...0.150) * sampleRate)
    }

    private func continueTahrir() {
        tahrirCount += 1
        if tahrirCount >= tahrirTotal {
            strikeNote(frequency: tahrirMainFreq, velocity: tahrirVel)
            state = .phraseNote
            if motifIndex < currentMotif.count {
                scheduleNextNote(currentDegree: previousDegree)
            } else { finishPhrase() }
            return
        }
        tahrirOnMain.toggle()
        let freq = tahrirOnMain ? tahrirMainFreq : tahrirUpperFreq
        let dynScale: Float = 0.40 + 0.20 * Float(tahrirCount) / Float(max(1, tahrirTotal))
        strikeNote(frequency: freq, velocity: tahrirVel * dynScale)
        samplesUntilEvent = Int(Double.random(in: 0.060...0.150) * sampleRate)
    }

    // MARK: - Eshare (ghost hint note)

    private func startEshare(degree: Int, freq: Double, vel: Float) {
        let offset = (Bool.random() ? 2 : -2) + (Bool.random() ? 1 : 0)
        let hintDeg = max(0, min(9, degree + offset))
        strikeNote(frequency: frequencyForDegree(hintDeg, ascending: Bool.random()),
                   velocity: Float.random(in: 0.015...0.030))
        eshareMainFreq = freq; eshareMainVel = vel; eshareMainDegree = degree
        state = .eshareWait
        samplesUntilEvent = Int(Double.random(in: 0.08...0.15) * sampleRate)
    }

    private func playMainAfterEshare() {
        strikeNote(frequency: eshareMainFreq, velocity: eshareMainVel)
        previousDegree = eshareMainDegree
        state = .phraseNote
        if motifIndex < currentMotif.count {
            scheduleNextNote(currentDegree: eshareMainDegree)
        } else { finishPhrase() }
    }

    // MARK: - Dorrab (rapid re-strikes)

    private func startDorrab(freq: Double, vel: Float) {
        dorrabFreq = freq; dorrabVel = vel
        dorrabTotal = Int.random(in: 2...4); dorrabCount = 0
        strikeNote(frequency: freq, velocity: vel * 0.6)
        state = .dorrab
        samplesUntilEvent = Int(Double.random(in: 0.050...0.080) * sampleRate)
    }

    private func continueDorrab() {
        dorrabCount += 1
        if dorrabCount >= dorrabTotal {
            strikeNote(frequency: dorrabFreq, velocity: dorrabVel)
            state = .phraseNote
            if motifIndex < currentMotif.count {
                scheduleNextNote(currentDegree: previousDegree)
            } else { finishPhrase() }
            return
        }
        let scale: Float = 0.5 + 0.2 * Float(dorrabCount)
        strikeNote(frequency: dorrabFreq, velocity: dorrabVel * min(scale, 0.9))
        samplesUntilEvent = Int(Double.random(in: 0.050...0.080) * sampleRate)
    }

    // MARK: - Cascade Glissando (rapid stepwise descent)

    private func startCascade(degree: Int, vel: Float) {
        let steps = Int.random(in: 4...7)
        cascadeDegrees = (0..<steps).map { max(0, degree - $0) }
        cascadeIdx = 0; cascadeVel = vel * 0.55
        strikeNote(frequency: frequencyForDegree(cascadeDegrees[0], ascending: false),
                   velocity: cascadeVel)
        cascadeIdx = 1
        state = .cascade
        samplesUntilEvent = Int(Double.random(in: 0.030...0.050) * sampleRate)
    }

    private func continueCascade() {
        if cascadeIdx >= cascadeDegrees.count {
            previousDegree = cascadeDegrees.last ?? previousDegree
            state = .phraseNote
            if motifIndex < currentMotif.count {
                scheduleNextNote(currentDegree: previousDegree)
            } else { finishPhrase() }
            return
        }
        let deg = cascadeDegrees[cascadeIdx]
        let scale: Float = 0.8 + 0.3 * Float(cascadeIdx) / Float(max(1, cascadeDegrees.count))
        strikeNote(frequency: frequencyForDegree(deg, ascending: false),
                   velocity: cascadeVel * min(scale, 1.0))
        previousDegree = deg
        cascadeIdx += 1
        samplesUntilEvent = Int(Double.random(in: 0.030...0.050) * sampleRate)
    }

    // MARK: - Riz (4 Types)

    private func startRiz(freq: Double, vel: Float) {
        state = .riz
        rizFreq = freq; rizStrikeNum = 0
        let g = gushehs[currentGushehIdx]
        if g.intensity > 0.65 { rizType = Bool.random() ? .kamel : .shetabi }
        else if g.intensity < 0.35 { rizType = Bool.random() ? .nimRiz : .kandi }
        else { rizType = [RizType.nimRiz, .kamel, .shetabi, .kandi].randomElement()! }
        switch rizType {
        case .nimRiz:  rizTotalStrikes = Int.random(in: 8...12);  rizBaseVel = vel * 0.50
        case .kamel:   rizTotalStrikes = Int.random(in: 20...40); rizBaseVel = vel * 0.55
        case .shetabi: rizTotalStrikes = Int.random(in: 15...25); rizBaseVel = vel * 0.50
        case .kandi:   rizTotalStrikes = Int.random(in: 15...25); rizBaseVel = vel * 0.55
        }
        rizStrikesLeft = rizTotalStrikes
        samplesUntilEvent = Int(Double.random(in: 0.10...0.14) * sampleRate)
    }

    private func continueRiz() {
        guard rizStrikesLeft > 0 else {
            state = .resting
            samplesUntilEvent = withRubato(Double.random(in: 2.5...5.0))
            return
        }
        let progress = Float(rizStrikeNum) / Float(max(1, rizTotalStrikes))
        let vel: Float
        switch rizType {
        case .nimRiz:
            vel = rizBaseVel * Float.random(in: 0.85...1.15)
        case .kamel:
            if progress < 0.20 {
                vel = rizBaseVel * (0.40 + 0.60 * (progress / 0.20))
            } else if progress < 0.60 {
                vel = rizBaseVel * Float.random(in: 0.93...1.07)
            } else {
                vel = rizBaseVel * (1.0 - (progress - 0.60) / 0.40 * 0.55)
            }
        case .shetabi:
            vel = rizBaseVel * (0.50 + 0.50 * progress) * Float.random(in: 0.92...1.08)
        case .kandi:
            vel = rizBaseVel * (1.0 - 0.50 * progress) * Float.random(in: 0.92...1.08)
        }
        strikeNote(frequency: rizFreq, velocity: max(vel, 0.025))
        rizStrikesLeft -= 1; rizStrikeNum += 1
        if rizStrikesLeft > 0 {
            let baseIOI: Double
            switch rizType {
            case .nimRiz:  baseIOI = Double.random(in: 0.075...0.100)
            case .kamel:
                if progress < 0.20 { baseIOI = Double.random(in: 0.10...0.14) }
                else if progress < 0.65 { baseIOI = Double.random(in: 0.080...0.110) }
                else { baseIOI = Double.random(in: 0.095...0.140) }
            case .shetabi: baseIOI = Double.random(in: 0.06...0.08) + Double(1.0 - progress) * 0.06
            case .kandi:   baseIOI = Double.random(in: 0.06...0.08) + Double(progress) * 0.07
            }
            let swing = rizStrikeNum % 2 == 0 ? 0.95 : 1.05
            let jitter = Double.random(in: -0.006...0.006)
            samplesUntilEvent = max(1, Int((baseIOI * swing + jitter) * sampleRate))
        } else {
            state = .resting
            samplesUntilEvent = withRubato(Double.random(in: 2.5...5.0))
        }
    }

    // MARK: - Phrase Finish

    private func finishPhrase() {
        state = .resting
        lastPhraseEndedOnFinalis = (currentMotif.last == 2)
        if Double.random(in: 0...1) < 0.12 {
            strikeNote(frequency: frequencyForDegree(0, ascending: true),
                       velocity: Float.random(in: 0.08...0.14))
            if Double.random(in: 0...1) < 0.40 {
                let g3freq = SanturSynthesizer.d4Hz * pow(2.0, (-1200.0 + 486.0) / 1200.0)
                strikeGhost(frequency: g3freq, velocity: 0.04)
            }
        }
        let g = gushehs[currentGushehIdx]
        let baseRest: Double
        if g.intensity < 0.35 { baseRest = Double.random(in: 2.5...5.5) }
        else if g.intensity < 0.55 { baseRest = Double.random(in: 1.8...4.0) }
        else if g.intensity < 0.70 { baseRest = Double.random(in: 1.2...2.8) }
        else { baseRest = Double.random(in: 0.8...2.2) }
        let multiplier = phrasesSinceForud == 0 ? 1.4 : 1.0
        samplesUntilEvent = withRubato(baseRest * multiplier)
    }

    // MARK: - Dynamics

    private func gushehVelocity(degree: Int) -> Float {
        let g = gushehs[currentGushehIdx]
        let total = max(Float(currentMotif.count), 1)
        let pos = Float(motifIndex)
        let norm = pos / max(total - 1, 1)
        let arch = sin(Float.pi * min(norm / 0.85, 1.0))
        let base: Float = 0.06; let peak: Float = 0.24
        var vel = base + (peak - base) * arch
        vel += Float(max(0, degree - 2)) * 0.010
        vel *= (0.65 + g.intensity * 0.50)
        vel += (g.brightness - 0.4) * 0.04
        if degree == g.shahed { vel *= 1.06 }
        if isForudPhrase && norm > 0.4 { vel *= 1.0 - (norm - 0.4) * 0.6 }
        return max(vel * Float.random(in: 0.88...1.12), 0.025)
    }

    // MARK: - Timing

    private func scheduleNextNote(currentDegree: Int) {
        let remaining = currentMotif.count - motifIndex
        let g = gushehs[currentGushehIdx]
        var delay: Double
        if remaining <= 1 { delay = Double.random(in: 0.55...1.1) }
        else if lastDirection > 0 { delay = Double.random(in: 0.22...0.48) }
        else if lastDirection < 0 { delay = Double.random(in: 0.38...0.80) }
        else { delay = Double.random(in: 0.28...0.60) }
        if currentDegree == g.shahed && Double.random(in: 0...1) < 0.35 { delay *= 1.5 }
        else if currentDegree == 2 && Double.random(in: 0...1) < 0.30 { delay *= 1.4 }
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
        var quietest = 0
        var lowest: Float = .infinity
        for i in 0..<voiceCount {
            let e = voices[i].energy
            if e < lowest { lowest = e; quietest = i }
        }
        voices[quietest].strike(frequency: frequency, velocity: velocity)
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
