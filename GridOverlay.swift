import SwiftUI

struct GridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let thirdWidth = width / 3
            let thirdHeight = height / 3
            
            Path { path in
                // Vertical lines
                path.move(to: CGPoint(x: thirdWidth, y: 0))
                path.addLine(to: CGPoint(x: thirdWidth, y: height))
                
                path.move(to: CGPoint(x: thirdWidth * 2, y: 0))
                path.addLine(to: CGPoint(x: thirdWidth * 2, y: height))
                
                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: thirdHeight))
                path.addLine(to: CGPoint(x: width, y: thirdHeight))
                
                path.move(to: CGPoint(x: 0, y: thirdHeight * 2))
                path.addLine(to: CGPoint(x: width, y: thirdHeight * 2))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.gray
        GridOverlay()
    }
}