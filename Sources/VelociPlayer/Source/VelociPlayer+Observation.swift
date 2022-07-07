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
    internal func onPlayerTimeChanged(time: VPTime) {
        self.progress = time.seconds / duration.seconds
        self.time = time
        Task.detached {
            await self.updateCaptions(time: time)
        }
    }
    
    internal func onPlayerTimeControlled() {
        switch self.timeControlStatus {
        case .paused:
            self.isPaused = true
            self.isBuffering = false
        case .playing:
            self.isPaused = false
            self.isBuffering = false
        case .waitingToPlayAtSpecifiedRate:
            self.isPaused = false
            self.isBuffering = true
        @unknown default:
            break
        }
        
        updateNowPlayingForSeeking()
    }
    
    internal func statusChanged() {
        switch self.status {
        case .readyToPlay:
            prepareForPlayback()
        case .unknown, .failed:
            currentError = .unableToBuffer
        @unknown default:
            break
        }
    }
    
    internal func startObservingPlayer() {
        timeObserver = self.addPeriodicTimeObserver(
            forInterval: VPTime(seconds: 0.1, preferredTimescale: 10_000),
            queue: .main
        ) { [weak self] time in
            self?.onPlayerTimeChanged(time: time)
        }
        
        self.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.onPlayerTimeControlled()
            }
            .store(in: &subscribers)
    }
    
    internal func prepareNewPlayerItem() {
        guard let mediaURL = mediaURL else { return }
        
        let playerItem = AVPlayerItem(url: mediaURL)
        playerItem.preferredForwardBufferDuration = 10
        self.replaceCurrentItem(with: playerItem)
        
        playerItem.publisher(for: \.isPlaybackBufferEmpty)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaybackBufferEmpty in
                if isPlaybackBufferEmpty {
                    self?.bufferStatusChanged(to: .empty)
                }
            }
            .store(in: &subscribers)
        
        playerItem.publisher(for: \.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaybackLikelyToKeepUp in
                if isPlaybackLikelyToKeepUp {
                    self?.bufferStatusChanged(to: .likelyToKeepUp)
                }
            }
            .store(in: &subscribers)
        
        playerItem.publisher(for: \.isPlaybackBufferFull)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaybackBufferFull in
                if isPlaybackBufferFull {
                    self?.bufferStatusChanged(to: .full)
                }
            }
            .store(in: &subscribers)
        
        playerItem.publisher(for: \.loadedTimeRanges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timeRanges in
                self?.updateBufferTime(timeRanges: timeRanges)
            }
            .store(in: &subscribers)
        
        Task.detached {
            await self.updateCurrentItemDuration()
        }
    }
}
