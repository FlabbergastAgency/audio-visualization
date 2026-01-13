import SwiftUI

struct ContentView: View {
    var body: some View {
        ViewControllerRepresentable()
    }
}

struct ViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        return
    }
}

#Preview {
    ContentView()
}
