//
//  GardenView.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 14/12/25.
//

import SwiftUI

struct GardenView: View {
    
    
    @State private var breathe = false
    @State private var seedActive = false
    @State private var seedPressed = false
    @State private var showPoem = false
    @State private var currentPoem: Poem? = nil
    @State private var discoveredPoemsID: Set <UUID> = []
    @State private var plantingPulse = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    
    var growthLevel: Int {
        discoveredPoemsID.count
    }
    
    var body: some View {
        
        ZStack{
            
            LinearGradient(
                
                gradient: Gradient(colors: [
                    Color.persianIndigo,
                    Color.persianTurquoise
                ]
                ),
                
                startPoint: .top,
                endPoint: .bottom
                
            ).ignoresSafeArea()
            
            
            


            VStack {
                
                Spacer()
                
                Circle()
                    .foregroundStyle(Color.persianGold.opacity(0.14))
                    .frame(width: 320, height: 320)
                    .blur(radius: 70)
                    .scaleEffect(breathe ? 1.03 : 0.97)
                    .opacity(breathe ? 0.12 + Double(growthLevel) * 0.03 : 0.08)
                    .animation (reduceMotion
                                ? .none : .easeInOut(duration: 8).repeatForever(autoreverses: true),
                                value: breathe)
                
                Circle()
                    .foregroundStyle(Color.persianTurquoise.opacity(0.35))
                    .frame(width: 80, height: 80)
                    .overlay (
                        Circle()
                            .stroke (Color.persianGold.opacity (0.6), lineWidth: 1.5))
                    .scaleEffect(seedPressed ? 0.95 : plantingPulse ? 0.6 : 1.0)
                    .opacity(seedActive ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 0.4), value: seedPressed)
                    .animation(.easeInOut(duration: 0.3), value: seedActive)
                
                
                    .onTapGesture {
                        guard !showPoem else { return }
                        guard let randomPoem = PoemLibrary.poems.randomElement() else { return }
                        
                        currentPoem = randomPoem
                        
                        seedActive.toggle()
                        
                        discoveredPoemsID.insert(randomPoem.id)
                        
                        plantingPulse = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            plantingPulse = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                showPoem = true
                            }
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.6) {
                        guard !showPoem else { return }
                        seedPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            seedPressed = false
                        }
                    }
                
                
                
                RoundedRectangle(cornerRadius: 42, style: .continuous)
                    .foregroundStyle(
                        LinearGradient(gradient: Gradient(colors: [
                            Color.persianSand,
                            Color.persianSaffron
                        ]),
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                    .frame(height: 360)
                    .scaleEffect (breathe ? 1.01 : 0.99)
                    .opacity (breathe ? 1.0 : 0.96)
                    .animation (reduceMotion
                                ? .none : .easeInOut (duration: 6) .repeatForever(autoreverses: true),
                                value: breathe)
                
            }.padding(.bottom, 24)
            
            VStack{
                Spacer()
                ZStack{
                    Text("growth: \(growthLevel)")
                        .foregroundStyle(.white)
                        .font(.caption)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding()

                    GardenElementView(
                        imageName:  "Plant",
                     isVisible: growthLevel >= 1,
                        size: 60,
                        step: 1
                    ).frame (maxWidth: .infinity, alignment: .leading)
                        .padding (.leading ,48)
                    
                    
                    GardenElementView(
                        imageName:  "Flower",
                     isVisible: growthLevel >= 2,
                        size: 84,
                        step: 2
                    ).frame (maxWidth: .infinity, alignment: .trailing)
                        .padding (.trailing ,48)
                    
                    GardenElementView(
                        imageName:  "Water",
                     isVisible: growthLevel >= 3,
                        size: 76,
                        step: 3)
                    
                    GardenElementView(
                        imageName:  "Stone",
                     isVisible: growthLevel >= 4,
                        size: 96,
                        step: 4
                    ).frame (maxWidth: .infinity, alignment: .leading)
                        .padding (.leading ,92)
                        .padding (.top, 44)
                }
                Spacer(minLength: 140)
            }.allowsHitTesting(false)
            
            //BundleInspectorView()
            
            if showPoem, let poem = currentPoem {
                ZStack{
                    
                    Color.black
                               .opacity(0.4)
                               .ignoresSafeArea()
                               .onTapGesture {
                                   withAnimation {
                                       showPoem = false
                                   }
                               }
                    
                    PoemOverlayView(
                        persian: poem.persian,
                        english: poem.english,
                        culturalNote: poem.culturalNote,
                        reflection: poem.reflection
                        
                    )
                    .zIndex(10)
                    
                }
            }
        }.task {
            if !breathe {breathe = true}
        }
       
    }
}
#Preview {
    GardenView()
}


