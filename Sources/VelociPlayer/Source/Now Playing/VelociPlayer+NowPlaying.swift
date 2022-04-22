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

#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit
public typealias NowPlayingImage = UIImage
#endif

#if os(macOS)
import AppKit
public typealias NowPlayingImage = NSImage
#endif

extension VelociPlayer {
    // MARK: - System Integration
    internal func updateNowPlayingForSeeking() {
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime().seconds
        nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = self.duration.seconds
        nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = self.rate
    }
    
    internal func setUpNowPlayingControls() {
        disableAllCommands()
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
    
    fileprivate func setUp(command: MPRemoteCommand, handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) {
        command.isEnabled = true
        if let target = commandTargets[command] {
          command.removeTarget(target)
          commandTargets.removeValue(forKey: command)
        }
        commandTargets[command] = command.addTarget(handler: handler)
    }
    
    internal func setUpScrubbing() {
        let command = MPRemoteCommandCenter.shared().changePlaybackPositionCommand
        setUp(command: command) { [weak self] event in
            guard let self = self,
                  let playbackPositionEvent = event as? MPChangePlaybackPositionCommandEvent
            else {
                return .commandFailed
            }
            
            self.seek(to: VPTime(seconds: playbackPositionEvent.positionTime, preferredTimescale: 10_000))
            return .success
        }
    }
    
    internal func setUpPlayCommand() {
        let command = MPRemoteCommandCenter.shared().playCommand
        setUp(command: command) { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.play()
            return .success
        }
    }
    
    internal func setUpPauseCommand() {
        let command = MPRemoteCommandCenter.shared().pauseCommand
        setUp(command: command) { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.pause()
            return .success
        }
    }
    
    internal func setUpSkipBackwardsCommand() {
        let command = MPRemoteCommandCenter.shared().skipBackwardCommand
        command.preferredIntervals = [NSNumber(value: seekInterval)]
        setUp(command: command) { [weak self] _  in
            guard let self = self else { return .commandFailed }
            self.rewind()
            return .success
        }
    }
    
    internal func setUpSkipForwardsCommand() {
        let command = MPRemoteCommandCenter.shared().skipForwardCommand
        command.preferredIntervals = [NSNumber(value: seekInterval)]
        setUp(command: command) { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.skipForward()
            return .success
        }
    }
    
    internal func setUpPreviousTrackCommand(with action: @escaping () -> Void) {
        let command = MPRemoteCommandCenter.shared().previousTrackCommand
        command.isEnabled = true
        setUp(command: command) { _ in
            action()
            return .success
        }
    }
    
    internal func setUpNextTrackCommand(with action: @escaping () -> Void) {
        let command = MPRemoteCommandCenter.shared().nextTrackCommand
        command.isEnabled = true
        setUp(command: command) { _ in
            action()
            return .success
        }
    }
    
    internal func disableAllCommands() {
        for (command, target) in commandTargets {
          command.isEnabled = false
          command.removeTarget(target)
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
        image: NowPlayingImage? = nil
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
    public func setNowPlayingImage(_ image: NowPlayingImage?) {
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
