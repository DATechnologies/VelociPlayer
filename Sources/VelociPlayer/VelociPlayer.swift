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

public class VelociPlayer: AVPlayer, ObservableObject {
    
    // MARK: - Variables
    /// The progress of the player: Ranges from 0 to 1.
    @Published public private(set) var progress = 0.0
    /// The  playback time of the current item.
    @Published public private(set) var currentTime = CMTime(seconds: 0, preferredTimescale: 1)
    @Published public private(set) var isPaused = true
    
    /// The total length of the currently playing item.
    @Published public var length = CMTime(seconds: 0, preferredTimescale: 1)
    
    /// Determines how many seconds the `rewind` and `skipForward` commands should skip. The default is `10.0`.
    public var seekInterval = 10.0 {
        didSet {
            if displayInSystemPlayer {
                setUpSkipForwardsCommand()
                setUpSkipBackwardsCommand()
            }
        }
    }
    
    /// Determines whether the player should integrate with the system to allow playback controls from Control Center and the Lock Screen, among other places.
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
        volume = 1.0
    }
    
    public override init(url: URL) {
        super.init()
        let playerItem = AVPlayerItem(url: url)
        self.replaceCurrentItem(with: playerItem)
        audioUrl = url
        volume = 1.0
        prepareForPlayback()
    }
    
    deinit {
        stop()
    }
    
    /// Start playing audio from a specified URL.
    /// - Parameter url: The URL containing an audio file to play.
    public func beginPlayback(from url: URL) {
        self.audioUrl = url
        let playerItem = AVPlayerItem(url: url)
        self.replaceCurrentItem(with: playerItem)
        prepareForPlayback()
        self.play()
    }
    
    private func prepareForPlayback() {
        Task {
            await currentItem?.asset.loadValues(forKeys: ["duration"])
            if let duration = currentItem?.asset.duration {
                await MainActor.run {
                    self.length = duration
                }
            }
        }
        
        startObservingPlayer()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        }
        catch {
            print("Error syncing with system player: \(error)")
        }
    }
    
    // MARK: - Player Observation
    func onPlayerTimeChanged(time: CMTime) {
        self.progress = time.seconds / length.seconds
        self.currentTime = time
    }
    
    func onPlayerTimeControlled() {
        switch self.timeControlStatus {
        case .waitingToPlayAtSpecifiedRate, .paused:
            self.isPaused = true
            Task { await updateNowPlayingForSeeking() }
        case .playing:
            self.isPaused = false
            Task { await updateNowPlayingForSeeking() }
        default:
            break
        }
    }
    
    func startObservingPlayer() {
        timeObserver = self.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 10000), queue: .main) { [weak self] time in
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
    }
}
