//
//  GardenElementView.swift
//  WhispersoftheGardenApp
//
//  Created by Nima Khodarahmi on 27/12/25.
//

import Foundation
import SwiftUI

struct GardenElementView: View {
    
    let imageName: String
    let isVisible: Bool
    let size: CGFloat
    let step: Int
    
    
    var body: some View {
        
        BundlePNGImage(fileName: "\(imageName).png", size: size)
            .scaledToFit()
            .frame(width: size)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect (isVisible ? 1 : 0.6)
            .blur (radius: isVisible ? 0 : 8)
            .animation(.easeInOut(duration: 2.2), value: isVisible)
    }
}
