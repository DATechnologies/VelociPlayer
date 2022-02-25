//
//  VelociPlayer+Observation.swift
//  
//
//  Created by Ethan Humphrey on 2/22/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    // MARK: - Player Observation
    internal func onPlayerTimeChanged(time: CMTime) {
        self.progress = time.seconds / duration.seconds
        self.time = time
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
    
    internal func prepareNewPlayerItem() {
        if let mediaURL = mediaURL {
            let playerItem = AVPlayerItem(url: mediaURL)
            playerItem.preferredForwardBufferDuration = 10
            self.replaceCurrentItem(with: playerItem)
            
            playerItem.publisher(for: \.isPlaybackBufferEmpty)
                .sink { [weak self] isPlaybackBufferEmpty in
                    if isPlaybackBufferEmpty {
                        self?.bufferStatusChanged(to: .empty)
                    }
                }
                .store(in: &subscribers)

            playerItem.publisher(for: \.isPlaybackLikelyToKeepUp)
                .sink { [weak self] isPlaybackLikelyToKeepUp in
                    if isPlaybackLikelyToKeepUp {
                        self?.bufferStatusChanged(to: .likelyToKeepUp)
                    }
                }
                .store(in: &subscribers)

            playerItem.publisher(for: \.isPlaybackBufferFull)
                .sink { [weak self] isPlaybackBufferFull in
                    if isPlaybackBufferFull {
                        self?.bufferStatusChanged(to: .full)
                    }
                }
                .store(in: &subscribers)
            
            playerItem.publisher(for: \.loadedTimeRanges)
                .sink { [weak self] timeRanges in
                    self?.updateBufferTime(timeRanges: timeRanges)
                }
                .store(in: &subscribers)
        }
    }
}
