//
//  VelociPlayer+NowPlaying.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 2/1/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    @MainActor
    internal func updateNowPlayingForSeeking() {
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime().seconds
        nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = self.length.seconds
        nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = self.rate
    }
    
    // MARK: - System Integration
    internal func setUpNowPlaying() {
        setUpPlayCommand()
        setUpPauseCommand()
        setUpSkipBackwardsCommand()
        setUpSkipForwardsCommand()
        setUpScrubbing()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    internal func removeFromNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    private func setUpScrubbing() {
        let command = MPRemoteCommandCenter.shared().changePlaybackPositionCommand
        
        command.isEnabled = true
        command.addTarget { [weak self] event in
            guard let self = self,
                  let playbackPositionEvent = event as? MPChangePlaybackPositionCommandEvent
                    else { return .commandFailed }
            
            self.seek(to: CMTime(seconds: playbackPositionEvent.positionTime, preferredTimescale: 10000))
            return .success
        }
    }
    
    private func setUpPlayCommand() {
        let command = MPRemoteCommandCenter.shared().playCommand
        command.isEnabled = true
        command.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.play()
            return .success
        }
    }
    
    private func setUpPauseCommand() {
        let command = MPRemoteCommandCenter.shared().pauseCommand
        
        command.isEnabled = true
        command.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.pause()
            return .success
        }
    }
    
    internal func setUpSkipBackwardsCommand() {
        let command = MPRemoteCommandCenter.shared().skipBackwardCommand
        
        command.isEnabled = true
        command.preferredIntervals = [NSNumber(value: seekInterval)]
        command.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.rewind()
            return .success
        }
    }
    
    internal func setUpSkipForwardsCommand() {
        let command = MPRemoteCommandCenter.shared().skipForwardCommand
        
        command.isEnabled = true
        command.preferredIntervals = [NSNumber(value: seekInterval)]
        command.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.skipForward()
            return .success
        }
    }
    
    /// Set the information that displays in the system player which appears in Control Center, on the Lock Screen, etc. Automatically enables `displayInSystemPlayer`/
    /// - Parameters:
    ///   - title: The title to display for the current item.
    ///   - artist: The artist to display for the current item.
    ///   - albumName: The album name to display for the current item.
    ///   - image: The image to display for the current item.
    public func setNowPlayingInfo(
        title: String? = nil,
        artist: String? = nil,
        albumName: String? = nil,
        image: UIImage? = nil
    ) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumName
        nowPlayingInfo[MPMediaItemPropertyAssetURL] = mediaURL
        self.nowPlayingInfo = nowPlayingInfo
        
        setNowPlayingImage(image)
        
        displayInSystemPlayer = true
    }
    
    /// Set the image that displays in the system player which appears in Control Center, on the Lock Screen, etc.
    /// - Parameter image: The image to display for the current item.
    public func setNowPlayingImage(_ image: UIImage?) {
        guard let image = image else { return }
        
        nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
            return image
        }
    }
    
    /// Add a custom property for the system player.
    /// - Parameters:
    ///   - propertyName: The name of the custom property.
    ///   - value: The value of the custom property.
    public func addNowPlayingProperty(propertyName: String, value: Any?) {
        nowPlayingInfo?[propertyName] = value
    }
}
