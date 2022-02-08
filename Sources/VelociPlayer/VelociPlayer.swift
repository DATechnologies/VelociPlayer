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
    /// The progress of the player: Ranges from 0 to 1.
    @Published public var progress = 0.0
    /// The  playback time of the current item.
    @Published public var currentTime = CMTime(seconds: 0, preferredTimescale: 1)
    @Published public var isPaused = true
    
    /// The total length of the currently item.
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
        super.init(url: url)
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
            self.length = currentItem?.duration ?? CMTime(seconds: 0, preferredTimescale: 1)
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
}
