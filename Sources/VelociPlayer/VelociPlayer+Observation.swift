//
//  VelociPlayer+Observation.swift
//  
//
//  Created by Ethan Humphrey on 2/1/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    // MARK: - Player Observation
    func onPlayerTimeChanged(time: CMTime) {
        self.progress = time.seconds / length.seconds
        self.currentTime = time
    }
    
    func onPlayerTimeControlled() {
        switch self.timeControlStatus {
        case .waitingToPlayAtSpecifiedRate, .paused:
            self.isPaused = true
            Task { await updateNowPlayingForSeeking(didComplete: false) }
        case .playing:
            self.isPaused = false
            Task { await updateNowPlayingForSeeking(didComplete: true) }
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
