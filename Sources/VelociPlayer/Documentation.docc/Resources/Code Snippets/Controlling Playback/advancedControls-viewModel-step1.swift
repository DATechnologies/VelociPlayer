import Combine
import VelociPlayer

@MainActor
class ExampleViewModel: ObservableObject {
    
    var player: VelociPlayer
    var cancellables: [AnyCancellable] = []
    
    @Published var isPaused = false
    @Published var isBuffering = true
    @Published var progress = 0.0
    
    @Published var showCompletionMessage = false
    
    init() {
        player = VelociPlayer(autoPlay: true, mediaURL: URL("https://rapptrlabs.com/my-video-url"))
        player.seekInterval = 15
        beginPlayerObservation()
    }
    
    func seek(to progress: Double) async {
        let success = await player.seek(toPercent: progress)
        // Perform an action after seeking.
    }
    
    func togglePlayback() {
        player.togglePlayback()
    }
    
    func rewind() {
        player.rewind()
    }
    
    func skipForward() {
        player.skipForward()
    }
    
    private func beginPlayerObservation() {
        player.$isPaused.assign(to: &$isPaused)
        player.$isBuffering.assign(to: &$isBuffering)
        
        player.$progress
            .sink { [weak self] progress in
                self?.progressUpdated(progress)
            }
            .store(in: &cancellables)
    }
    
    private func progressUpdated(_ progress: Double) {
        self.progress = progress
        if (progress >= 1) {
            userFinishedMedia()
        }
    }
    
    private func userFinishedMedia() {
        showCompletionMessage = true
    }
}
