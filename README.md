# VelociPlayer

Welcome to VelociPlayer, [Rapptr Labs](https://rapptrlabs.com)' iOS audio and video player toolkit.

VelociPlayer is a subclass of `AVPlayer` which enables rapid development of audio and video players.

## Integration Example

This example uses a SwiftUI view:

```swift
public struct AudioPlayerView: View {
    @ObservedObject public var player: VelociPlayer

    public var body: some View {
        VStack {
            // Play/Pause Button
            Button {
                player.togglePlayback()
            } label: {
                Image(
                    systemName: player.isPaused ?
                        "play.circle.fill" : 
                        "pause.circle.fill"
                )
            }
            
            HStack {
                Text("\(player.time.seconds)")
                
                Spacer()
                
                Text("\(player.duration.seconds)")
            }
        }
    }
}
```

You can initialize an instance of `VelociPlayer` with the URL to your content like so:

```swift
let player = VelociPlayer(
    autoPlay: true,
    mediaURL: URL(string: "...")
)
```
