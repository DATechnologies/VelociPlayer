import Combine
import VelociPlayer

@MainActor
class ExampleViewModel: ObservableObject {
    
    var player: VelociPlayer
    var cancellables: [AnyCancellable] = []
    
    @Published var isPaused = false
    @Published var isBuffering = true
    @Published var progress = 0.0
    
    init() {
        player = VelociPlayer(autoPlay: true, mediaURL: URL("https://rapptrlabs.com/my-video-url"))
        beginPlayerObservation()
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
    }
}
