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
    @Published public var currentTime = CMTime(seconds: 0, preferredTimescale: 1)
    
    /// Indicates if playback is currently paused.
    @Published public private(set) var isPaused = true
    
    /// Indicates if the player is currently loading content.
    @Published public private(set) var isBuffering = false
    
    /// The total length of the currently playing item.
    @Published public var length = CMTime(seconds: 0, preferredTimescale: 1)
    
    public var autoPlay = false
    
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
    
    /// Specifies the audio mode for the system. Set this to `.default` for standard audio and `.moviePlayback` for videos.
    public var audioMode: AVAudioSession.Mode = .default {
        didSet {
            setAVCategory()
        }
    }
    
    public enum MediaType {
        case audio, video
    }
    
    /// The source URL of the media file
    public var mediaURL: URL? {
        didSet {
            if let mediaURL = mediaURL {
                let playerItem = AVPlayerItem(url: mediaURL)
                self.replaceCurrentItem(with: playerItem)
            }
        }
    }
    
    internal var timeObserver: Any?
    internal var subscribers: [AnyCancellable] = []
    
    internal var nowPlayingInfo: [String: Any]? {
        didSet {
            guard displayInSystemPlayer else { return }
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    // MARK: - Initialization
    public init(autoPlay: Bool = false, mediaURL: URL? = nil) {
        super.init()
        volume = 1.0
        self.mediaURL = mediaURL
        self.publisher(for: \.status)
            .sink { [weak self] status in
                self?.statusChanged()
            }
            .store(in: &subscribers)
    }
    
    deinit {
        stop()
    }
    
    internal func prepareForPlayback() {
        Task {
            await currentItem?.asset.loadValues(forKeys: ["duration"])
            
            if let duration = currentItem?.asset.duration {
                await MainActor.run {
                    self.length = duration
                    self.isBuffering = true
                }
            }
            
            let isLoaded = await preroll(atRate: 1.0)
            await MainActor.run {
                self.isBuffering = !isLoaded
                if autoPlay {
                    self.play()
                }
            }
        }
    }
    
    internal func setAVCategory() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: audioMode)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[VelociPlayer] Error while communicating with AVAudioSession", error.localizedDescription)
        }
    }
    
    // MARK: - Player Observation
    internal func onPlayerTimeChanged(time: CMTime) {
        self.progress = time.seconds / length.seconds
        self.currentTime = time
    }
    
    internal func onPlayerTimeControlled() {
        switch self.timeControlStatus {
        case .paused:
            self.isPaused = true
            self.isBuffering = false
            Task { await updateNowPlayingForSeeking() }
        case .playing:
            self.isPaused = false
            self.isBuffering = false
            Task { await updateNowPlayingForSeeking() }
        case .waitingToPlayAtSpecifiedRate:
            self.isPaused = false
            self.isBuffering = true
            Task { await updateNowPlayingForSeeking() }
        default:
            break
        }
    }
    
    internal func statusChanged() {
        switch self.status {
        case .unknown:
            break
        case .failed:
            break
        case .readyToPlay:
            prepareForPlayback()
        @unknown default:
            break
        }
    }
    
    internal func startObservingPlayer() {
        timeObserver = self.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 10000), queue: .main) { [weak self] time in
            self?.onPlayerTimeChanged(time: time)
        }
        
        self.publisher(for: \.timeControlStatus)
            .sink { [weak self] time in
                self?.onPlayerTimeControlled()
            }
            .store(in: &subscribers)
        
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: nil)
            .sink { [weak self] _ in
                self?.progress = 1
            }
            .store(in: &subscribers)
    }
}
