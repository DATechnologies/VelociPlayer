//
//  File.swift
//  
//
//  Created by Ethan Humphrey on 2/1/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    // MARK: - Controls
    /// Rewind the player based on the `seekInterval`
    public func rewind() {
        let newTime = currentTime().seconds - self.seekInterval
        seek(to: newTime)
    }
    
    /// Go forward based on the `seekInterval`
    public func skipForward() {
        let newTime = currentTime().seconds + self.seekInterval
        seek(to: newTime)
    }
    
    ///  Toggles playback for the current item.
    public func togglePlayback() {
        if isPaused {
            play()
        } else {
            pause()
        }
    }
    
    /// Stop playback and end any observation on the player.
    public func stop() {
        self.pause()
        if let timeObserver = timeObserver {
            self.removeTimeObserver(timeObserver)
        }
        timeControlSubscriber?.cancel()
        playEndedSubscriber?.cancel()
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
