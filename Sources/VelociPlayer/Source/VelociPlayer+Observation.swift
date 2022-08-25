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
        case .failed:
            currentError = .unableToBuffer
        case .unknown:
            break
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
    
    internal func mediaURLChanged() {
        let currentURL = ((self.currentItem?.asset) as? AVURLAsset)?.url
        guard let mediaURL = mediaURL, currentURL != mediaURL else { return }
        
        let playerItem = AVPlayerItem(url: mediaURL)
        self.replaceCurrentItem(with: playerItem)
    }
    
    internal func prepareNewPlayerItem() {
        self.currentItemSubscribers = []
        guard let currentItem = self.currentItem else {
            return
        }
        self.mediaURL = (currentItem.asset as? AVURLAsset)?.url
        currentItem.preferredForwardBufferDuration = 10
        
        currentItem.publisher(for: \.isPlaybackBufferEmpty)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaybackBufferEmpty in
                if isPlaybackBufferEmpty {
                    self?.bufferStatusChanged(to: .empty)
                }
            }
            .store(in: &currentItemSubscribers)
        
        currentItem.publisher(for: \.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaybackLikelyToKeepUp in
                if isPlaybackLikelyToKeepUp {
                    self?.bufferStatusChanged(to: .likelyToKeepUp)
                }
            }
            .store(in: &currentItemSubscribers)
        
        currentItem.publisher(for: \.isPlaybackBufferFull)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaybackBufferFull in
                if isPlaybackBufferFull {
                    self?.bufferStatusChanged(to: .full)
                }
            }
            .store(in: &currentItemSubscribers)
        
        currentItem.publisher(for: \.loadedTimeRanges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timeRanges in
                self?.updateBufferTime(timeRanges: timeRanges)
            }
            .store(in: &currentItemSubscribers)
        
        currentItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                switch status {
                case .failed:
                    self.currentError = .unableToBuffer
                default:
                    break
                }
            }
            .store(in: &currentItemSubscribers)
        
        Task.detached {
            await self.updateCurrentItemDuration()
        }
    }
}
