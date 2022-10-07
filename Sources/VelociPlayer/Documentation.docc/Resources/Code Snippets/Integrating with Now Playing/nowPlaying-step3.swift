import Combine
import SwiftUI
import VelociPlayer

@MainActor
class AudioPlayerViewModel: ObservableObject {
    
    var player: VelociPlayer
    
    @Published var isPaused = false
    @Published var isBuffering = true
    @Published var progress = 0.0
    
    init() {
        player = VelociPlayer(autoPlay: true, mediaURL: URL("https://rapptrlabs.com/my-video-url"))
        beginPlayerObservation()
        setUpNowPlaying()
    }
    
    private func setUpNowPlaying() {
        let artwork = UIImage(named: "nowPlayingArtwork")
        player.setNowPlayingInfo(
            title: "Why you NEED to integrate with Now Playing!",
            artist: "Rapptr Labs",
            albumName: "VelociPlayer Tutorials",
            image: artwork
        )
    }
    
    private func beginPlayerObservation() {
        player.$isPaused.assign(to: &$isPaused)
        player.$isBuffering.assign(to: &$isBuffering)
        player.$progress.assign(to: &$progress)
    }
}

struct AudioPlayerView: View {
    
    @StateObject var viewModel = AudioPlayerViewModel()
    
    var body: some View {
        VStack {
            Text(String(format: "%2f", viewModel.progress * 100) + "%")
            
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
