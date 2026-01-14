import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WaveCircleViewControllerRepresentable()
                .tabItem {
                    Text("Basic Audio Visualization")
                        .multilineTextAlignment(.center)
                }
            UnknownPleasuresViewControllerRepresentable()
                .tabItem {
                    Text("Unknown Pleasures")
                        .multilineTextAlignment(.center)
                }
        }
    }
}

#Preview {
    ContentView()
}
