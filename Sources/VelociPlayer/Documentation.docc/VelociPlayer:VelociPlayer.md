# ``VelociPlayer/VelociPlayer``

An audio/video player that makes playback easily to implement, utilizing Combine to subscribe to changes.

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

## Overview

VelociPlayer is an `AVPlayer` subclass that aims to take the headache out
of adding an audio/video player in your app. Simply provide the URL of an
audio or video file and VelociPlayer will handle the rest. You can subscribe to
the publishers on each property using Combine to get updates when values change,
such as the current playback progress, or if the player is buffering. This
allows you to directly use it in a SwiftUI view if so desired.

> Important: You _must_ call ``stop()`` when you're done using the player. 
If you do not, it may remain in memory for longer than intended, 
and may play audio in the background.

## Topics

### Observation
- ``bufferProgress``
- ``bufferTime``
- ``currentError``
- ``duration``
- ``isBuffering``
- ``isPaused``
- ``progress``
- ``time``

### Customization
- ``audioCategory``
- ``audioMode``
- ``autoPlay``
- ``displayInSystemPlayer``
- ``mediaURL``
- ``seekInterval``
- ``startTime``

### Controls
- ``pause()``
- ``play()``
- ``reload()``
- ``rewind()``
- ``skipForward()``
- ``stop()``
- ``togglePlayback()``

### Seeking
- ``seek(to:)-kk9t``
- ``seek(to:)-4bcam``
- ``seek(to:)-2ju0p``
- ``seek(to:)-9dta7``
- ``seek(toPercent:)-5y56o``
- ``seek(to:)-1esu3``
- ``seek(to:)-994zn``
- ``seek(toPercent:)-8bp62``
- ``seek(to:toleranceBefore:toleranceAfter:)-80yhs``
- ``seek(to:toleranceBefore:toleranceAfter:)-62mwn``

### Now Playing
- ``setNowPlayingInfo(title:artist:albumName:image:)``
- ``setNowPlayingImage(_:)``
- ``addNowPlayingProperty(propertyName:value:)``
- ``displayInSystemPlayer``
- ``nowPlayingConfiguration``

### Captions
- ``setUpCaptions(for:)-94xgp``
- ``setUpCaptions(for:)-1ieyg``
- ``removeCaptions()``
- ``currentCaption``
- ``allCaptions``
