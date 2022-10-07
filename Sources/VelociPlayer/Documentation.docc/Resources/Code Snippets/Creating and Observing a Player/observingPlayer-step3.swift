import Combine
import SwiftUI
import VelociPlayer

struct ExampleView: View {
    
    @StateObject var viewModel = ExampleViewModel()
    
    var body: some View {
        VStack {
            Text(String(format: "%.2f", viewModel.progress * 100) + "%")
            
            if viewModel.isBuffering {
                ProgressView()
            }
            
            Button {
                // TODO: Implement Playback Toggling!
            } label: {
                Image(systemName: viewModel.isPaused ? "play" : "pause")
            }
        }
    }
}

@MainActor
class ExampleViewModel: ObservableObject {
    
    var player: VelociPlayer
    
    @Published var isPaused = false
    @Published var isBuffering = true
    @Published var progress = 0.0
    
    init() {
        player = VelociPlayer(autoPlay: true, mediaURL: URL(string: "https://rapptrlabs.com/my-video-url"))
        player.$isPaused.assign(to: &$isPaused)
        player.$isBuffering.assign(to: &$isBuffering)
        player.$progress.assign(to: &$progress)
    }
}
