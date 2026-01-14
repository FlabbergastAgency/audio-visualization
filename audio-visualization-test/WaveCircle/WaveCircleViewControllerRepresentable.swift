import UIKit
import SwiftUI

struct WaveCircleViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WaveCircleViewController {
        return WaveCircleViewController()
    }
    
    func updateUIViewController(_ uiViewController: WaveCircleViewController, context: Context) {
        return
    }
}
