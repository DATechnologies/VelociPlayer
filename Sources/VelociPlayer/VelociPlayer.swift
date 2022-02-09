//
//  VelociPlayer.swift
//  VelociPlayer
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
            guard displayInSystemPlayer else { return }
            
            setUpSkipForwardsCommand()
            setUpSkipBackwardsCommand()
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
    
    /// The source URL of the media file
    public private(set) var mediaURL: URL?
    
    internal var timeObserver: Any?
    internal var cancellables: [AnyCancellable] = []
    
    internal var nowPlayingInfo: [String: Any]? {
        didSet {
            guard displayInSystemPlayer else { return }
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    // MARK: - Initialization
    public override init() {
        super.init()
        
        volume = 1.0
    }
    
    /// Initialize a new `VelociPlayer` object with a `mediaURL`
    ///
    /// Can throw because setting the `AVAudioSession` category, and setting it to active, throw.
    public init(mediaURL: URL) throws {
        super.init()
        
        let playerItem = AVPlayerItem(url: mediaURL)
        self.replaceCurrentItem(with: playerItem)
        
        self.mediaURL = mediaURL
        volume = 1.0
        
        try prepareForPlayback()
    }
    
    deinit {
        stop()
        cancellables.removeAll()
    }
    
    /// Start playing audio from a specified URL.
    /// - Parameter url: The URL containing an audio file to play.
    public func beginPlayback(from mediaURL: URL) throws {
        self.mediaURL = mediaURL
        
        let playerItem = AVPlayerItem(url: mediaURL)
        self.replaceCurrentItem(with: playerItem)
        
        try prepareForPlayback()
        
        self.play()
    }
    
    private func prepareForPlayback() throws {
        Task {
            await currentItem?.asset.loadValues(forKeys: ["duration"])
            
            if let duration = currentItem?.asset.duration {
                await MainActor.run {
                    self.length = duration
                }
            }
        }
        
        startObservingPlayer()
        
        try AVAudioSession.sharedInstance().setCategory(.playback)
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
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
        
        self.publisher(for: \.timeControlStatus)
            .sink(receiveValue: { [weak self] time in
                self?.onPlayerTimeControlled()
            })
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: nil)
            .sink { [weak self] _ in
                self?.progress = 1
            }
            .store(in: &cancellables)
    }
}
