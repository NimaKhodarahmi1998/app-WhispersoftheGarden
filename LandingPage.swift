//
//  LandingPage.swift - WITH OPTIONS BUTTON
//  WhispersoftheGardenApp
//
//  Your complete landing page with both buttons
//

import SwiftUI
import AVFoundation

// MARK: - Landing Particle System

private struct LandingMote {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var speed: CGFloat
    var drift: CGFloat
    var phase: CGFloat
    var warmth: CGFloat
    var cachedColor: Color
}

private final class LandingParticleData: ObservableObject, @unchecked Sendable {
    private var motes: [LandingMote] = []
    private var lastTime: TimeInterval = 0
    private var initialized = false

    private func setup(size: CGSize) {
        guard !initialized else { return }
        initialized = true
        for _ in 0..<18 {
            motes.append(Self.makeMote(in: size, randomY: true))
        }
    }

    func update(time: TimeInterval, size: CGSize) {
        let dt = lastTime == 0 ? 0.016 : min(time - lastTime, 0.05)
        lastTime = time
        if !initialized { setup(size: size) }

        for i in motes.indices {
            let sway = CGFloat(sin(time * 0.5 + Double(motes[i].phase))) * 12.0
            motes[i].y -= motes[i].speed * CGFloat(dt)
            motes[i].x += (motes[i].drift + sway) * CGFloat(dt)

            let pulse = CGFloat(sin(time * 1.2 + Double(motes[i].phase) * 2.0))
            motes[i].opacity = (0.2 + motes[i].warmth * 0.15) + pulse * 0.1

            if motes[i].y < -30 {
                motes[i] = Self.makeMote(in: size, randomY: false)
                motes[i].y = size.height + CGFloat.random(in: 5...30)
            }
            if motes[i].x < -30 { motes[i].x = size.width + 20 }
            if motes[i].x > size.width + 30 { motes[i].x = -20 }
        }
    }

    func render(in context: inout GraphicsContext, size: CGSize) {
        for mote in motes {
            var ctx = context
            ctx.translateBy(x: mote.x, y: mote.y)
            let r = mote.size
            let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)
            let color = mote.cachedColor
            ctx.fill(
                Circle().path(in: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        color.opacity(Double(mote.opacity)),
                        color.opacity(Double(mote.opacity) * 0.25),
                        .clear
                    ]),
                    center: .zero,
                    startRadius: 0,
                    endRadius: r
                )
            )
        }
    }

    private static func makeMote(in size: CGSize, randomY: Bool) -> LandingMote {
        let w = CGFloat.random(in: 0...1)
        return LandingMote(
            x: .random(in: 0...size.width),
            y: randomY ? .random(in: 0...size.height) : size.height + .random(in: 5...30),
            size: .random(in: 2.0...4.5),
            opacity: .random(in: 0.15...0.4),
            speed: .random(in: 8...20),
            drift: .random(in: -6...6),
            phase: .random(in: 0...(2 * .pi)),
            warmth: w,
            cachedColor: Color(
                red: 1.0,
                green: 0.88 - Double(w) * 0.08,
                blue: 0.55 - Double(w) * 0.15
            )
        )
    }
}

private struct LandingParticleCanvas: View {
    var reduceMotion: Bool = false
    @StateObject private var system = LandingParticleData()

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation) { timeline in
                Canvas(rendersAsynchronously: false) { context, size in
                    system.update(
                        time: timeline.date.timeIntervalSinceReferenceDate,
                        size: size
                    )
                    system.render(in: &context, size: size)
                }
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Gold Ornamental Divider

private struct GoldOrnamentDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            line
            ornament
            line
        }
        .frame(height: 10)
        .padding(.horizontal, 60)
    }

    private var line: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color(red: 0.85, green: 0.70, blue: 0.35), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    private var ornament: some View {
        // Arabesque-style diamond with nested shapes
        ZStack {
            // Outer diamond
            Diamond()
                .stroke(Color(red: 0.85, green: 0.70, blue: 0.35), lineWidth: 1.2)
                .frame(width: 8, height: 8)
            // Inner dot
            Circle()
                .fill(Color(red: 0.90, green: 0.75, blue: 0.40))
                .frame(width: 2.5, height: 2.5)
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: cy))
        path.addLine(to: CGPoint(x: cx, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: cy))
        path.closeSubpath()
        return path
    }
}

// MARK: - Persian Tile Style

private let tileGold = Color(red: 0.82, green: 0.68, blue: 0.32)

private struct PersianTileModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            // Gold tile border
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(tileGold.opacity(0.6), lineWidth: 1.5)
            )
            // Glazed ceramic highlight along the top edge
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            )
            // Raised shadow (deep layer)
            .shadow(color: Color.black.opacity(0.55), radius: 6, x: 0, y: 5)
            // Ambient soft glow
            .shadow(color: tileGold.opacity(0.15), radius: 10, x: 0, y: 0)
    }
}

extension View {
    fileprivate func persianTileStyle() -> some View {
        modifier(PersianTileModifier())
    }
}

// MARK: - Landing Page

struct LandingPage: View {

    @Binding var showMainApp: Bool
    @Binding var showOptions: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    private let audio = GardenAudioEngine.shared

    // Dynamic Type scaled base sizes (phone values — iPad uses multiplier)
    @ScaledMetric(relativeTo: .title3) private var headingBase: CGFloat = 19
    @ScaledMetric(relativeTo: .title3) private var buttonTextBase: CGFloat = 20
    @ScaledMetric(relativeTo: .caption) private var quoteEnglishBase: CGFloat = 11
    @ScaledMetric(relativeTo: .caption2) private var quotePersianBase: CGFloat = 9
    @ScaledMetric(relativeTo: .caption2) private var quoteAttrBase: CGFloat = 7

    // Fade-in animation state
    @State private var showHeading = false
    @State private var showDivider = false
    @State private var showButtons = false
    @State private var showQuote = false
    @State private var buttonsInteractive = false

    var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    private let navyCenter = Color(red: 10/255, green: 45/255, blue: 90/255)
    private let navyEdge   = Color(red: 2/255,  green: 18/255, blue: 48/255)

    var body: some View {
        GeometryReader { geometry in
            let videoHeight = geometry.size.height * (isIPad ? 0.5 : 0.4)

            ZStack(alignment: .top) {
                // Full-bleed radial gradient background
                RadialGradient(
                    gradient: Gradient(colors: [navyCenter, navyEdge]),
                    center: UnitPoint(x: 0.5, y: 0.6),
                    startRadius: 20,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.8
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Video at the top with a long fade into the background
                    OneShotVideoPlayer(videoName: "Heading3", videoExt: "MOV")
                        .frame(maxWidth: .infinity)
                        .frame(height: videoHeight)
                        .clipped()
                        .mask(
                            VStack(spacing: 0) {
                                Color.white
                                LinearGradient(
                                    colors: [.white, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: videoHeight * 0.35)
                            }
                        )

                    Spacer()
                }

                // Ambient floating particles (full screen, behind content)
                LandingParticleCanvas(reduceMotion: reduceMotion)
                    .padding(.top, videoHeight * 0.7)

                // Content positioned below the video fade
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: videoHeight)

                    // Heading
                    Text("Listen closely — the garden is whispering")
                        .font(.custom("Didot", size: isIPad ? headingBase * 1.47 : headingBase))
                        .italic()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                        .opacity(showHeading ? 1 : 0)
                        .offset(y: showHeading ? 0 : geometry.size.height * 0.015)
                        .accessibilityAddTraits(.isHeader)

                    // 3. Gold ornamental divider
                    GoldOrnamentDivider()
                        .padding(.vertical, isIPad ? 16 : 12)
                        .opacity(showDivider ? 1 : 0)

                    // Enter Your Garden button
                    Button {
                        audio.playSFX(.gentleTap)
                        showMainApp = true
                    } label: {
                        ZStack {
                            Image("Button1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: min(geometry.size.width * 0.8, 400))

                            Text("Enter Your Garden")
                                .font(.custom("Palatino-Bold", size: isIPad ? buttonTextBase * 1.4 : buttonTextBase))
                                .tracking(isIPad ? 2 : 1.2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.96, blue: 0.82),
                                            Color(red: 0.88, green: 0.78, blue: 0.50)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .black, radius: 0, x: -1, y: -1)
                                .shadow(color: .black, radius: 0, x: 1, y: -1)
                                .shadow(color: .black, radius: 0, x: -1, y: 1)
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                                .minimumScaleFactor(0.6)
                        }
                        .persianTileStyle()
                    }
                    .accessibilityLabel("Enter Your Garden")
                    .accessibilityHint("Double tap to enter the garden")
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : geometry.size.height * 0.012)
                    .allowsHitTesting(buttonsInteractive)
                    .padding(.bottom, isIPad ? 22 : 16)

                    // Options button
                    Button {
                        audio.playSFX(.gentleTap)
                        showOptions = true
                    } label: {
                        ZStack {
                            Image("Button2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: min(geometry.size.width * 0.8, 400))

                            Text("Options")
                                .font(.custom("Palatino-Bold", size: isIPad ? buttonTextBase * 1.4 : buttonTextBase))
                                .tracking(isIPad ? 2 : 1.2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.96, blue: 0.82),
                                            Color(red: 0.88, green: 0.78, blue: 0.50)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .black, radius: 0, x: -1, y: -1)
                                .shadow(color: .black, radius: 0, x: 1, y: -1)
                                .shadow(color: .black, radius: 0, x: -1, y: 1)
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                                .minimumScaleFactor(0.6)
                        }
                        .persianTileStyle()
                    }
                    .accessibilityLabel("Options")
                    .accessibilityHint("Double tap to open settings")
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : geometry.size.height * 0.012)
                    .allowsHitTesting(buttonsInteractive)

                    Spacer()

                    // 4. Persian poetry quote — Hafez
                    VStack(spacing: 4) {
                        Text("Glad tidings — the days of sorrow shall not last")
                            .font(.system(size: isIPad ? quoteEnglishBase * 1.27 : quoteEnglishBase, design: .serif))
                            .italic()
                        Text("رسید مژده که ایام غم نخواهد ماند")
                            .font(.system(size: isIPad ? quotePersianBase * 1.33 : quotePersianBase))
                        Text("— Hafez")
                            .font(.system(size: isIPad ? quoteAttrBase * 1.43 : quoteAttrBase, design: .serif))
                    }
                    .foregroundColor(Color.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, isIPad ? 30 : 16)
                    .opacity(showQuote ? 1 : 0)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Persian verse by Hafez: Glad tidings, the days of sorrow shall not last")
                }
            }
            .ignoresSafeArea(edges: .all)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        // 5. Sequential fade-in animations
        .onAppear { playEntrance() }
        .onChange(of: showOptions) { newValue in
            // Options just dismissed — reset and replay entrance
            if !newValue {
                buttonsInteractive = false
                showHeading = false
                showDivider = false
                showButtons = false
                showQuote = false
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    playEntrance()
                }
            }
        }
    }

    private func playEntrance() {
        buttonsInteractive = false
        if reduceMotion {
            showHeading = true
            showDivider = true
            showButtons = true
            showQuote = true
            buttonsInteractive = true
        } else {
            withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
                showHeading = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                showDivider = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
                showButtons = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(1.5)) {
                showQuote = true
            }
            // Enable interaction only after button animation finishes
            // (1.0s delay + 0.6s duration = 1.6s)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_700_000_000)
                buttonsInteractive = true
            }
        }
    }

    struct OneShotVideoPlayer: UIViewRepresentable {
        let videoName: String
        let videoExt: String

        func makeUIView(context: Context) -> PlayerView {
            return PlayerView(videoName: videoName, videoExt: videoExt)
        }

        func updateUIView(_ uiView: PlayerView, context: Context) {
            uiView.updatePlayerLayerFrame()
        }

        class PlayerView: UIView {
            private var player: AVPlayer?
            private var playerLayer: AVPlayerLayer?

            init(videoName: String, videoExt: String) {
                super.init(frame: .zero)

                guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExt) else {
                    backgroundColor = UIColor(red: 10/255, green: 45/255, blue: 90/255, alpha: 1)
                    return
                }

                let player = AVPlayer(url: url)
                let playerLayer = AVPlayerLayer(player: player)

                playerLayer.videoGravity = .resizeAspectFill
                layer.addSublayer(playerLayer)

                self.player = player
                self.playerLayer = playerLayer

                backgroundColor = UIColor(red: 10/255, green: 45/255, blue: 90/255, alpha: 1)

                player.isMuted = true
                player.play()
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            override func removeFromSuperview() {
                player?.pause()
                playerLayer?.removeFromSuperlayer()
                player = nil
                super.removeFromSuperview()
            }

            override func layoutSubviews() {
                super.layoutSubviews()
                playerLayer?.frame = bounds
            }

            func updatePlayerLayerFrame() {
                playerLayer?.frame = bounds
            }
        }
    }
}
