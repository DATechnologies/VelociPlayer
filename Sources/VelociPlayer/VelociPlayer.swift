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
    @Published public internal(set) var progress = 0.0
    
    /// The playback time of the current item.
    @Published public internal(set) var currentTime = CMTime(seconds: 0, preferredTimescale: 1)
    
    /// Indicates if playback is currently paused.
    @Published public internal(set) var isPaused = true
    
    /// Indicates if the player is currently loading content.
    @Published public internal(set) var isBuffering = false
    
    /// The furthest point of the current item that is currently buffered.
    @Published public internal(set) var bufferTime = CMTime(seconds: 0, preferredTimescale: 1)
    
    /// The furthest point of the current item that is currently buffered, represented at a decimal.
    @Published public internal(set) var bufferProgress = 0.0
    
    /// The total length of the currently playing item.
    @Published public internal(set) var length = CMTime(seconds: 0, preferredTimescale: 1)
    
    /// Specifies whether the player should automatically begin playback once the item has finished loading.
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
            prepareNewPlayerItem()
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
        self.autoPlay = autoPlay
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
            try AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: audioMode)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[VelociPlayer] Error while communicating with AVAudioSession", error.localizedDescription)
        }
    }
}
