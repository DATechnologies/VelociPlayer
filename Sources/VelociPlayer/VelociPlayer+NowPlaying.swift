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
    // MARK: - System Integration
    @MainActor
    internal func updateNowPlayingForSeeking() {
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime().seconds
        nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = self.duration.seconds
        nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = self.rate
    }
    
    internal func setUpNowPlayingControls() {
        disableAllControls()
        setUpMainControl()
        if nowPlayingConfiguration.allowScrubbing {
            setUpScrubbing()
        }
        setUpPreviousControl()
        setUpForwardControl()
    }
    
    internal func removeFromNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    internal func setUpMainControl() {
        switch nowPlayingConfiguration.mainControl {
        case .playPause:
            setUpPlayCommand()
            setUpPauseCommand()
        }
    }
    
    internal func setUpPreviousControl() {
        switch nowPlayingConfiguration.previousControl {
        case .none:
            break
        case .skip:
            setUpSkipBackwardsCommand()
        case .previousTrack(let action):
            setUpPreviousTrackCommand(with: action)
        }
    }
    
    internal func setUpForwardControl() {
        switch nowPlayingConfiguration.forwardControl {
        case .none:
            break
        case .skip:
            setUpSkipForwardsCommand()
        case .nextTrack(let action):
            setUpNextTrackCommand(with: action)
        }
    }
    
    internal func setUpScrubbing() {
        let command = MPRemoteCommandCenter.shared().changePlaybackPositionCommand
        command.isEnabled = true
        if let target = commandTargets[command] {
            command.removeTarget(target)
            commandTargets.removeValue(forKey: command)
        }
        commandTargets[command] = command.addTarget { [weak self] event in
            guard let self = self,
                  let playbackPositionEvent = event as? MPChangePlaybackPositionCommandEvent
            else {
                return .commandFailed
            }
            
            self.seek(to: CMTime(seconds: playbackPositionEvent.positionTime, preferredTimescale: 10_000))
            return .success
        }
    }
    
    internal func setUpPlayCommand() {
        let command = MPRemoteCommandCenter.shared().playCommand
        command.isEnabled = true
        if let target = commandTargets[command] {
            command.removeTarget(target)
            commandTargets.removeValue(forKey: command)
        }
        commandTargets[command] = command.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.play()
            return .success
        }
    }
    
    internal func setUpPauseCommand() {
        let command = MPRemoteCommandCenter.shared().pauseCommand
        command.isEnabled = true
        if let target = commandTargets[command] {
            command.removeTarget(target)
            commandTargets.removeValue(forKey: command)
        }
        commandTargets[command] = command.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.pause()
            return .success
        }
    }
    
    internal func setUpSkipBackwardsCommand() {
        let command = MPRemoteCommandCenter.shared().skipBackwardCommand
        command.isEnabled = true
        command.preferredIntervals = [NSNumber(value: seekInterval)]
        if let target = commandTargets[command] {
            command.removeTarget(target)
            commandTargets.removeValue(forKey: command)
        }
        commandTargets[command] = command.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.rewind()
            return .success
        }
    }
    
    internal func setUpSkipForwardsCommand() {
        let command = MPRemoteCommandCenter.shared().skipForwardCommand
        command.isEnabled = true
        command.preferredIntervals = [NSNumber(value: seekInterval)]
        if let target = commandTargets[command] {
            command.removeTarget(target)
            commandTargets.removeValue(forKey: command)
        }
        commandTargets[command] = command.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.skipForward()
            return .success
        }
    }
    
    internal func setUpPreviousTrackCommand(with action: @escaping () -> Void) {
        let command = MPRemoteCommandCenter.shared().previousTrackCommand
        command.isEnabled = true
        if let target = commandTargets[command] {
            command.removeTarget(target)
            commandTargets.removeValue(forKey: command)
        }
        commandTargets[command] = command.addTarget { _ in
            action()
            return .success
        }
    }
    
    internal func setUpNextTrackCommand(with action: @escaping () -> Void) {
        let command = MPRemoteCommandCenter.shared().nextTrackCommand
        command.isEnabled = true
        if let target = commandTargets[command] {
            command.removeTarget(target)
            commandTargets.removeValue(forKey: command)
        }
        commandTargets[command] = command.addTarget { _ in
            action()
            return .success
        }
    }
    
    internal func disableAllControls() {
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = false
        MPRemoteCommandCenter.shared().playCommand.isEnabled = false
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = false
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = false
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = false
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = false
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = false
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
        artwork: MPMediaItemArtwork? = nil
    ) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumName
        nowPlayingInfo[MPMediaItemPropertyAssetURL] = mediaURL
        self.nowPlayingInfo = nowPlayingInfo
        
        setNowPlayingArtwork(artwork)
        
        if !displayInSystemPlayer {
            displayInSystemPlayer = true
        }
    }
    
    /// Set the image that displays in the system player which appears in Control Center, on the Lock Screen, etc.
    /// - Parameter image: The image to display for the current item.
    public func setNowPlayingArtwork(_ artwork: MPMediaItemArtwork?) {
        nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
    }
    
    #if os(iOS)
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
        
        if !displayInSystemPlayer {
            displayInSystemPlayer = true
        }
    }
    
    /// Set the image that displays in the system player which appears in Control Center, on the Lock Screen, etc.
    /// - Parameter image: The image to display for the current item.
    public func setNowPlayingImage(_ image: UIImage?) {
        guard let image = image else { return }
        
        nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
            return image
        }
    }
    #endif
    
    /// Add a custom property for the system player.
    /// - Parameters:
    ///   - propertyName: The name of the custom property.
    ///   - value: The value of the custom property.
    public func addNowPlayingProperty(propertyName: String, value: Any?) {
        nowPlayingInfo?[propertyName] = value
    }
}
