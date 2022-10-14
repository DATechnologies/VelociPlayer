import Combine
import SwiftUI
import VelociPlayer

@MainActor
class VideoPlayerViewModel: ObservableObject {
    
    var player: VelociPlayer
    
    @Published var isPaused = false
    @Published var isBuffering = true
    @Published var progress = 0.0
    
    init() {
        player = VelociPlayer(autoPlay: true, mediaURL: URL(string: "https://rapptrlabs.com/my-video-url"))
        beginPlayerObservation()
    }
    
    private func beginPlayerObservation() {
        player.$isPaused.assign(to: &$isPaused)
        player.$isBuffering.assign(to: &$isBuffering)
        player.$progress.assign(to: &$progress)
    }
    
    func togglePlayback() {
        player.togglePlayback()
    }
}

struct VideoPlayerView: View {
    
    @StateObject var viewModel = VideoPlayerViewModel()
    
    var body: some View {
        ZStack {
            VideoView(player: viewModel.player)
            
            VStack {
                Text(String(format: "%.2f", viewModel.progress * 100) + "%")
                
                if viewModel.isBuffering {
                    ProgressView()
                }
                
                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPaused ? "play" : "pause")
                }
            }
        }
    }
}
