import SwiftUI
import UIKit

struct UnknownPleasuresViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UnknownPleasuresViewController {
        return UnknownPleasuresViewController()
    }
    
    func updateUIViewController(_ uiViewController: UnknownPleasuresViewController, context: Context) {
        return
    }
}

