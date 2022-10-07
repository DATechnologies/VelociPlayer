import Combine
import SwiftUI
import VelociPlayer

struct ExampleView: View {
    
    @StateObject var viewModel = ExampleViewModel()
    
    var body: some View {
        Text("Hello World!")
    }
}

@MainActor
class ExampleViewModel: ObservableObject {
    
    var player: VelociPlayer
    
    @Published var isPaused = false
    @Published var isBuffering = true
    @Published var progress = 0.0
    
    init() {
        player = VelociPlayer(autoPlay: true, mediaURL: URL("https://rapptrlabs.com/my-video-url"))
    }
}
