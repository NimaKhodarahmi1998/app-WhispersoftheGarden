//
//  GardenAudioEngine.swift
//  WhispersoftheGardenApp
//
//  Central audio engine: ambient santur synthesis + SFX playback.
//  Singleton accessed from SwiftUI views via GardenAudioEngine.shared.
//

import AVFoundation
import Combine

// @unchecked Sendable: iOS 16 View isn't @MainActor, so views access
// GardenAudioEngine.shared from non-isolated context. Volume/isPlaying
// properties are naturally atomic on ARM64. Audio graph mutations are
// single-threaded (setUp called once from startEngine on main).
final class GardenAudioEngine: ObservableObject, @unchecked Sendable {

    static let shared = GardenAudioEngine()

    // MARK: - Published Settings (UserDefaults-backed)

    @Published var isMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "audio_musicEnabled")
            santur?.isPlaying = isMusicEnabled && isEngineRunning
        }
    }

    @Published var musicVolume: Float {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: "audio_musicVolume")
            santur?.volume = musicVolume
        }
    }

    @Published var isSFXEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSFXEnabled, forKey: "audio_sfxEnabled")
        }
    }

    // MARK: - Audio Graph

    private let engine = AVAudioEngine()
    private var santur: SanturSynthesizer!
    private var santurSource: AVAudioSourceNode?

    private let reverb = AVAudioUnitReverb()

    // SFX playback: 3 player nodes round-robin through a shared mixer
    private var sfxPlayers: [AVAudioPlayerNode] = []
    private var sfxPlayerIndex = 0
    private var monoFmt: AVAudioFormat?
    private var cachedSampleRate: Double = 44100

    private var isEngineRunning = false
    private var isSetUp = false

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: "audio_musicEnabled") == nil {
            defaults.set(true, forKey: "audio_musicEnabled")
        }
        if defaults.object(forKey: "audio_musicVolume") == nil {
            defaults.set(Float(0.5), forKey: "audio_musicVolume")
        }
        if defaults.object(forKey: "audio_sfxEnabled") == nil {
            defaults.set(true, forKey: "audio_sfxEnabled")
        }

        self.isMusicEnabled = defaults.bool(forKey: "audio_musicEnabled")
        self.musicVolume = defaults.float(forKey: "audio_musicVolume")
        self.isSFXEnabled = defaults.bool(forKey: "audio_sfxEnabled")
    }

    // MARK: - Lazy Setup (called once from startEngine)

    private func setUp() {
        guard !isSetUp else { return }
        isSetUp = true

        // Activate audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("[GardenAudio] session error: \(error)")
        }

        // The ONLY correct sample rate: what the engine's output hardware uses
        let hwRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let sampleRate: Double = hwRate > 0 ? hwRate : 44100

        // Build synthesizer at the hardware rate
        santur = SanturSynthesizer(sampleRate: sampleRate)
        santur.volume = musicVolume

        // --- Build audio graph ---
        let monoFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        monoFmt = monoFormat
        cachedSampleRate = sampleRate

        let santurRef = santur!
        let sourceNode = AVAudioSourceNode(format: monoFormat) {
            isSilence, _, frameCount, bufferList -> OSStatus in

            let abl = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let data = abl[0].mData?.assumingMemoryBound(to: Float.self) else {
                isSilence.pointee = ObjCBool(true)
                return noErr
            }
            santurRef.render(frameCount: Int(frameCount), output: data)
            isSilence.pointee = ObjCBool(false)
            return noErr
        }
        santurSource = sourceNode

        reverb.loadFactoryPreset(.largeHall)
        reverb.wetDryMix = 40

        // SFX player nodes (3 for overlapping one-shot sounds)
        // SFX gets its own sub-mixer at reduced volume so santur stays on top
        let sfxMixer = AVAudioMixerNode()
        engine.attach(sfxMixer)
        sfxMixer.outputVolume = 0.35  // SFX is a subtle layer beneath the santur

        for _ in 0..<3 {
            let player = AVAudioPlayerNode()
            sfxPlayers.append(player)
            engine.attach(player)
            engine.connect(player, to: sfxMixer, format: monoFormat)
        }

        let sourceMixer = AVAudioMixerNode()
        engine.attach(sourceMixer)

        // Attach
        engine.attach(sourceNode)
        engine.attach(reverb)

        // Connect — santur at full volume, SFX at reduced volume, both into reverb
        // santurSource ─────────────────┐
        // sfxPlayer 0  ──┐              │
        // sfxPlayer 1  ──├── sfxMixer ──┤── sourceMixer ── reverb ── mainMixer
        // sfxPlayer 2  ──┘              │
        engine.connect(sourceNode, to: sourceMixer, format: monoFormat)
        engine.connect(sfxMixer, to: sourceMixer, format: monoFormat)
        engine.connect(sourceMixer, to: reverb, format: monoFormat)
        engine.connect(reverb, to: engine.mainMixerNode, format: monoFormat)
    }

    // MARK: - Public API

    func startEngine() {
        guard !isEngineRunning else { return }

        setUp()

        do {
            try engine.start()
            isEngineRunning = true

            // Santur plays immediately and continuously as background music
            if isMusicEnabled {
                santur.isPlaying = true
            }
        } catch {
            print("[GardenAudio] engine start failed: \(error)")
        }
    }

    func stopEngine() {
        guard isEngineRunning else { return }
        santur?.isPlaying = false
        engine.stop()
        isEngineRunning = false
    }

    func startAmbient() {
        guard isMusicEnabled, let santur else { return }
        santur.volume = musicVolume
        santur.isPlaying = true
    }

    func stopAmbient() {
        santur?.isPlaying = false
    }

    func fadeOutAmbient(duration: TimeInterval = 1.0) {
        guard let santur, santur.isPlaying else { return }

        let steps = 20
        let interval = duration / Double(steps)
        let startVolume = santur.volume
        let savedVolume = musicVolume
        let ref = santur  // capture strong reference — safe even if santur replaced

        Task { @MainActor in
            for step in 1...steps {
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                let progress = Float(step) / Float(steps)
                ref.volume = startVolume * (1.0 - progress)
            }
            ref.isPlaying = false
            ref.volume = savedVolume
        }
    }

    func playSFX(_ type: SFXType) {
        guard isSFXEnabled, isEngineRunning, let fmt = monoFmt, !sfxPlayers.isEmpty else { return }

        let samples = SFXBufferGen.generate(type, sampleRate: cachedSampleRate)
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: fmt,
                  frameCapacity: AVAudioFrameCount(samples.count)),
              let channelData = buffer.floatChannelData
        else { return }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        let dst = channelData[0]
        for i in 0..<samples.count { dst[i] = samples[i] }

        // Round-robin across player pool (allows overlapping sounds)
        let player = sfxPlayers[sfxPlayerIndex]
        sfxPlayerIndex = (sfxPlayerIndex + 1) % sfxPlayers.count
        player.stop()
        player.scheduleBuffer(buffer)
        player.play()
    }
}
