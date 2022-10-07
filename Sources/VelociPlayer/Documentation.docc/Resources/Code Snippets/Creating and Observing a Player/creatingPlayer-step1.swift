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
    
    init() {
        
    }
}
