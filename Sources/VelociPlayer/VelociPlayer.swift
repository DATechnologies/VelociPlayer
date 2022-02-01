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
}
