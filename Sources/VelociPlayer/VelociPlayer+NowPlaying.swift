//
//  VelociPlayer+NowPlaying.swift
//  
//
//  Created by Ethan Humphrey on 2/1/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    // MARK: - Seeking
    public func seek(toPercent percent: Double) {
        let seconds = self.length.seconds * percent
        self.seek(to: seconds)
    }
    
    public func seek(to seconds: TimeInterval) {
        self.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
    }
    
    override public func seek(to time: CMTime) {
        Task { await self.seek(to: time) }
    }
    
    override public func seek(to time: CMTime) async -> Bool {
        await updateNowPlayingForSeeking(didComplete: false)
        let completed = await super.seek(to: time)
        await updateNowPlayingForSeeking(didComplete: completed)
        return completed
    }
    
    override public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        Task { await self.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter) }
    }
    
    override public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) async -> Bool {
        await updateNowPlayingForSeeking(didComplete: false)
        let completed = await super.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
        await updateNowPlayingForSeeking(didComplete: completed)
        return completed
    }
    
    override public func seek(to date: Date) {
        Task { await self.seek(to: date) }
    }
    
    override public func seek(to date: Date) async -> Bool {
        await updateNowPlayingForSeeking(didComplete: false)
        let completed = await super.seek(to: date)
        await updateNowPlayingForSeeking(didComplete: completed)
        return completed
    }
    
    @MainActor
    func updateNowPlayingForSeeking(didComplete: Bool) {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.length.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = didComplete ? 1 : 0
    }
    
    // MARK: - System Integration
    func setUpNowPlaying() {
        setUpPlayCommand()
        setUpPauseCommand()
        setUpSkipBackwardsCommand()
        setUpSkipForwardsCommand()
        setUpScrubbing()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func removeFromNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func setUpScrubbing() {
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let playbackPositionEvent = event as? MPChangePlaybackPositionCommandEvent
                    else { return .commandFailed }
            
            self.seek(to: CMTime(seconds: playbackPositionEvent.positionTime, preferredTimescale: 10000))
            return .success
        }
    }
    
    func setUpPlayCommand() {
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.play()
            return .success
        }
    }
    
    func setUpPauseCommand() {
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.pause()
            return .success
        }
    }
    
    func setUpSkipBackwardsCommand() {
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [NSNumber(value: seekInterval)]
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.rewind()
            return .success
        }
    }
    
    func setUpSkipForwardsCommand() {
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [NSNumber(value: seekInterval)]
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { [weak self] _ in
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
    public func setNowPlayingInfo(title: String? = nil, artist: String? = nil, albumName: String? = nil, image: UIImage? = nil) {
        nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumName
        
        setNowPlayingImage(image)
        
        displayInSystemPlayer = true
    }
    
    /// Set the image that displays in the system player which appears in Control Center, on the Lock Screen, etc.
    /// - Parameter image: The image to display for the current item.
    public func setNowPlayingImage(_ image: UIImage?) {
        guard let image = image else { return }
        
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
            return image
        }
    }
    
    /// Add a custom property for the system player.
    /// - Parameters:
    ///   - propertyName: The name of the custom property.
    ///   - value: The value of the custom property.
    public func addNowPlayingProperty(propertyName: String, value: Any?) {
        nowPlayingInfo[propertyName] = value
    }
}
