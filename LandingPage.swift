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
                            
                            GardenView()
                        } label: {
                            ZStack{
                                Image(uiImage: UIImage(named: "Button1.PNG")!)
                                    .resizable()
                                    .scaledToFit()
                                    .frame (width: min(geometry.size.width * 0.8 , 400))
                                
                                ZStack {
                                    Text("Enter Your Garden")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                        .offset(x: -2, y: -2)

                                    Text("Enter Your Garden")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                        .offset(x: 2, y: -2)

                                    Text("Enter Your Garden")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                        .offset(x: -2, y: 2)

                                    Text("Enter Your Garden")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                        .offset(x: 2, y: 2)

                                    Text("Enter Your Garden")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.white)
                                }
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
                                
                                ZStack {
                                    Text("Options")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                        .offset(x: -2, y: -2)

                                    Text("Options")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                        .offset(x: 2, y: -2)

                                    Text("Options")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                        .offset(x: -2, y: 2)

                                    Text("Options")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                        .offset(x: 2, y: 2)

                                    Text("Options")
                                        .font(.custom("Snell Roundhand", size: isIPad ? 35 : 25))
                                        .fontWeight(.black)
                                        .foregroundColor(.white)
                                }
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
    
    
    
    struct LoopingVideoPlayer: UIViewControllerRepresentable {
        let videoName: String
        let videoExt: String
        
        func makeUIViewController(context: Context) -> AVPlayerViewController {
            let controller = AVPlayerViewController()
            
            guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExt) else {
                print("❌ Video not found")
                return controller
            }
            
            print("✅ Loading video from: \(url)")
            
            let playerItem = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: playerItem)
            
            // Configure player
            player.isMuted = true
            player.actionAtItemEnd = .pause // Pause at end instead of showing controls
            
            // Configure controller
            controller.player = player
            controller.showsPlaybackControls = true
            controller.allowsPictureInPicturePlayback = false
            controller.updatesNowPlayingInfoCenter = false
            controller.entersFullScreenWhenPlaybackBegins = false
            controller.exitsFullScreenWhenPlaybackEnds = false
            
            // Additional: Remove all interactive elements
            controller.view.isUserInteractionEnabled = false
            
            controller.view.backgroundColor = UIColor(
                red: 0/255,
                green: 32/255,
                blue: 72/255,
                alpha: 1
            )
            
            // Start playing
            player.play()
            
            print("✅ Player started")
            
            return controller
        }
        
        func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
            // Nothing needed here
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator()
        }
        
        class Coordinator {
        }
    }
}
