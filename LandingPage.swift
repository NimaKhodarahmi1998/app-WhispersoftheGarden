//
//  LandingPage.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 30/01/26.
//

import SwiftUI
import AVKit
import AVFoundation

struct LandingPage: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    
                    // Video at the top
                    LoopingVideoPlayer(videoName: "Heading3", videoExt: "MOV")
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * (isIPad ? 0.5 : 0.4)) // Adjust height as needed
                        .clipped()
                    
                    // Content below the video
                    VStack {
                        Text("Feel the GROWTH in your own whispering garden")
                            .font(.custom("Papyrus", size: isIPad ? 30 : 20))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                                                       .padding(.horizontal, 20)
                                                       .padding(.top, isIPad ? 40 : 20)
                                                       .minimumScaleFactor(0.5)
                                                       .lineLimit(3)
                        
                        
                        
                        NavigationLink {
                            
                            MainAppView()
                        } label: {
                            ZStack{
                                Image(uiImage: UIImage(named: "Button1.PNG")!)
                                    .resizable()
                                    .scaledToFit()
                                    .frame (width: min(geometry.size.width * 0.8 , 400))
                                
                                Text("Enter Your Garden")
                                    .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 0, y: -1)
                                    .shadow(color: .black, radius: 0, x: 0, y: 1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 0)
                                    .shadow(color: .black, radius: 0, x: 1, y: 0)
                                    .minimumScaleFactor(0.6)

                            }
                        }
                        
                        NavigationLink {
                            GardenView()
                        } label: {
                            ZStack{
                                Image(uiImage: UIImage(named: "Button2.PNG")!)
                                    .resizable()
                                    .scaledToFit()
                                    .frame (width: min(geometry.size.width * 0.8 , 400))
                                
                                Text("Options")
                                    .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 0, y: -1)
                                    .shadow(color: .black, radius: 0, x: 0, y: 1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 0)
                                    .shadow(color: .black, radius: 0, x: 1, y: 0)
                                    .minimumScaleFactor(0.6)
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Color(
                            red: 0/255,
                            green: 32/255,
                            blue: 72/255
                        )
                    )
                }
                .ignoresSafeArea(edges: .all)
                
                
            }
        }
    }
    
    
    
    struct LoopingVideoPlayer: UIViewRepresentable {
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
                    backgroundColor = UIColor(red: 0/255, green: 32/255, blue: 72/255, alpha: 1)
                    return
                }
                
                let player = AVPlayer(url: url)
                let playerLayer = AVPlayerLayer(player: player)
                
                playerLayer.videoGravity = .resizeAspectFill
                layer.addSublayer(playerLayer)
                
                self.player = player
                self.playerLayer = playerLayer
                
                backgroundColor = UIColor(red: 0/255, green: 32/255, blue: 72/255, alpha: 1)
                
                // Configure player
                player.isMuted = true
                player.play()
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
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
