//
//  VelociPlayer.swift
//
//
//  Created by Ethan Humphrey on 1/21/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

public class VelociPlayer: AVPlayer {
    
    // MARK: - Variables
    @Published public var progress = 0.0
    @Published public var currentTime = CMTime(seconds: 0, preferredTimescale: 1)
    @Published public var isPaused = true
    
    public var length: CMTime {
        currentItem?.duration ?? CMTime(seconds: 0, preferredTimescale: 1)
    }
    
    public var seekInterval = 10.0 {
        didSet {
            if displayInSystemPlayer {
                setUpSkipForwardsCommand()
                setUpSkipBackwardsCommand()
            }
        }
    }
    
    public var displayInSystemPlayer = false {
        didSet {
            if displayInSystemPlayer {
                setUpNowPlaying()
            } else {
                removeFromNowPlaying()
            }
        }
    }
    
    public private(set) var audioUrl: URL?
    
    var timeObserver: Any?
    var timeControlSubscriber: AnyCancellable?
    var playEndedSubscriber: AnyCancellable?
    var rateSubscriber: AnyCancellable?
    
    var nowPlayingInfo = [String: Any]() {
        didSet {
            if displayInSystemPlayer {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    
    // MARK: - Initialization
    public override init() {
        super.init()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Controls
    /// Start playing audio from a specified URL.
    /// - Parameter url: The URL containing an audio file to play.
    public func beginPlayback(from url: URL) {
        self.audioUrl = url
        let playerItem = AVPlayerItem(url: url)
        self.replaceCurrentItem(with: playerItem)
        volume = 1.0
        
        startObservingPlayer()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        }
        catch {
            print("Error syncing with system player: \(error)")
        }
        
        self.play()
    }
    
    public func rewind() {
        let newTime = currentTime().seconds - self.seekInterval
        seek(to: newTime)
    }
    
    public func skipForward() {
        let newTime = currentTime().seconds + self.seekInterval
        seek(to: newTime)
    }
    
    public func stop() {
        if let timeObserver = timeObserver {
            self.removeTimeObserver(timeObserver)
        }
        timeControlSubscriber?.cancel()
        playEndedSubscriber?.cancel()
        rateSubscriber?.cancel()
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    // MARK: - Player Observation
    func onPlayerTimeChanged(time: CMTime) {
        self.progress = time.seconds/length.seconds
        self.currentTime = time
    }
    
    func onPlayerTimeControlled() {
        switch self.timeControlStatus {
        case .waitingToPlayAtSpecifiedRate, .paused:
            updateNowPlayingForSeeking(didComplete: false)
        case .playing:
            updateNowPlayingForSeeking(didComplete: true)
        default:
            break
        }
    }
    
    func startObservingPlayer() {
        timeObserver = self.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.005, preferredTimescale: 10000), queue: .main) { [weak self] time in
            self?.onPlayerTimeChanged(time: time)
        }
        
        timeControlSubscriber = self.publisher(for: \.timeControlStatus)
            .sink(receiveValue: { [weak self] time in
                self?.onPlayerTimeControlled()
            })
        
        playEndedSubscriber = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: nil)
            .sink { [weak self] _ in
                self?.progress = 1
            }
        
        rateSubscriber = self.publisher(for: \.rate)
            .sink(receiveValue: { [weak self] rate in
                self?.isPaused = rate == 0
            })
    }
    
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
        updateNowPlayingForSeeking(didComplete: false)
        let completed = await super.seek(to: time)
        updateNowPlayingForSeeking(didComplete: completed)
        return completed
    }
    
    override public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        Task { await self.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter) }
    }
    
    override public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) async -> Bool {
        updateNowPlayingForSeeking(didComplete: false)
        let completed = await super.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
        updateNowPlayingForSeeking(didComplete: completed)
        return completed
    }
    
    override public func seek(to date: Date) {
        Task { await self.seek(to: date) }
    }
    
    override public func seek(to date: Date) async -> Bool {
        updateNowPlayingForSeeking(didComplete: false)
        let completed = await super.seek(to: date)
        updateNowPlayingForSeeking(didComplete: completed)
        return completed
    }
    
    private func updateNowPlayingForSeeking(didComplete: Bool) {
        self.nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime().seconds
        self.nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.length.seconds
        self.nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = didComplete ? 1 : 0
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
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { [weak self](remoteEvent) -> MPRemoteCommandHandlerStatus in
            guard let self = self,
                  let playbackPositionEvent = remoteEvent as? MPChangePlaybackPositionCommandEvent
                    else { return .commandFailed }
            
            self.seek(to: CMTime(seconds: playbackPositionEvent.positionTime, preferredTimescale: 1))
            return .success
        }
    }
    
    func setUpPlayCommand() {
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.play()
            return .success
        }
    }
    
    func setUpPauseCommand() {
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.pause()
            return .success
        }
    }
    
    func setUpSkipBackwardsCommand() {
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [NSNumber(value: seekInterval)]
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.rewind()
            return .success
        }
    }
    
    func setUpSkipForwardsCommand() {
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [NSNumber(value: seekInterval)]
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.skipForward()
            return .success
        }
    }
    
    public func setNowPlayingInfo(title: String?, artist: String?, albumName: String?, image: UIImage? = nil) {
        nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumName
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.length.seconds
        
        setNowPlayingImage(image)
        
        displayInSystemPlayer = true
    }
    
    public func setNowPlayingImage(_ image: UIImage?) {
        guard let image = image else { return }
        
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
            return image
        }
    }
    
    public func addNowPlayingProperty(propertyName: String, value: Any?) {
        nowPlayingInfo[propertyName] = value
    }
}
