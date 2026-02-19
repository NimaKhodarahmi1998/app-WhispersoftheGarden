//
//  GardenAudioEngine.swift
//  WhispersoftheGardenApp
//
//  Central audio engine: ambient santur synthesis + SFX playback.
//  Singleton accessed from SwiftUI views via GardenAudioEngine.shared.
//

import AVFoundation
import Combine

final class GardenAudioEngine: ObservableObject, @unchecked Sendable {

    static let shared = GardenAudioEngine()

    // MARK: - Published Settings (UserDefaults-backed)

    @Published var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "audio_soundEnabled") }
    }

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

    // MARK: - Audio Graph

    private let engine = AVAudioEngine()
    private var santur: SanturSynthesizer!
    private var santurSource: AVAudioSourceNode?

    private var sfxPlayers: [AVAudioPlayerNode] = []
    private var sfxRoundRobin: Int = 0

    private let reverb = AVAudioUnitReverb()

    private var sfxBuffers: [SFXType: AVAudioPCMBuffer] = [:]
    private var isEngineRunning = false
    private var isSetUp = false

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: "audio_soundEnabled") == nil {
            defaults.set(true, forKey: "audio_soundEnabled")
        }
        if defaults.object(forKey: "audio_musicEnabled") == nil {
            defaults.set(true, forKey: "audio_musicEnabled")
        }
        if defaults.object(forKey: "audio_musicVolume") == nil {
            defaults.set(Float(0.5), forKey: "audio_musicVolume")
        }

        self.isSoundEnabled = defaults.bool(forKey: "audio_soundEnabled")
        self.isMusicEnabled = defaults.bool(forKey: "audio_musicEnabled")
        self.musicVolume = defaults.float(forKey: "audio_musicVolume")
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

        // Build synthesizer + SFX at the hardware rate
        santur = SanturSynthesizer(sampleRate: sampleRate)
        santur.volume = musicVolume

        for type in SFXType.allCases {
            sfxBuffers[type] = SFXGenerator.generateBuffer(for: type, sampleRate: sampleRate)
        }

        // --- Build audio graph ---
        let monoFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

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

        // Attach
        engine.attach(sourceNode)
        engine.attach(reverb)

        // 4 SFX player nodes
        for _ in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            sfxPlayers.append(player)
        }

        // Connect — use explicit mono format everywhere to avoid silent mismatches
        // Ambient: sourceNode → reverb → mainMixer
        engine.connect(sourceNode, to: reverb, format: monoFormat)
        engine.connect(reverb, to: engine.mainMixerNode, format: monoFormat)

        // SFX: each player → mainMixer directly (mono buffers → mono connection)
        for player in sfxPlayers {
            engine.connect(player, to: engine.mainMixerNode, format: monoFormat)
        }
    }

    // MARK: - Public API

    func startEngine() {
        guard !isEngineRunning else { return }

        setUp()

        do {
            try engine.start()
            isEngineRunning = true

            for player in sfxPlayers {
                player.play()
            }

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

        Task { @MainActor in
            for step in 1...steps {
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                let progress = Float(step) / Float(steps)
                self.santur?.volume = startVolume * (1.0 - progress)
            }
            self.santur?.isPlaying = false
            self.santur?.volume = self.musicVolume
        }
    }

    func playSFX(_ type: SFXType) {
        guard isSoundEnabled, isEngineRunning else { return }
        guard let buffer = sfxBuffers[type] else { return }

        let player = sfxPlayers[sfxRoundRobin % sfxPlayers.count]
        sfxRoundRobin += 1

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
}
