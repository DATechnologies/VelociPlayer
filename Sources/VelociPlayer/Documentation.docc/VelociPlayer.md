# ``VelociPlayer``

A modern player to easily and swiftly integrate audio/video playback.

## Overview

VelociPlayer is an `AVPlayer` subclass that aims to take the headache out
of adding an audio/video player in your app. Simply provide the URL of an
audio or video file and VelociPlayer will handle the rest. You can subscribe to
the publishers on each property using Combine to get updates when values change,
such as the current playback progress, or if the player is buffering. This
allows you to directly use it in a SwiftUI view if so desired.

## Topics

### The Basics

- <doc:Table-of-Contents>
- ``VelociPlayer/VelociPlayer``
- ``VPTime``
- ``VelociPlayerError``

### Integrating with Now Playing
- ``NowPlayingConfiguration``
- ``NowPlayingImage``

### Implementing Captions

- ``Caption``
- ``CaptionDecoder``
