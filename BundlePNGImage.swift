import SwiftUI
import UIKit

struct BundlePNGImage: View {
    let fileName: String   
    let size: CGFloat
    
    var body: some View {
        if let uiImage = loadFromBundle(fileName: fileName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red, lineWidth: 2)
                .frame(width: size, height: size)
                .overlay(
                    Text("Missing\n\(fileName)")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                )
        }
    }
    
    private func loadFromBundle(fileName: String) -> UIImage? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let url = resourceURL.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }
}
