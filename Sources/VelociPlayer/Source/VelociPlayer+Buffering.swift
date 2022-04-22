//
//  VelociPlayer+Buffering.swift
//  
//
//  Created by Ethan Humphrey on 2/13/22.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

extension VelociPlayer {
    
    internal func bufferStatusChanged(to status: BufferStatus) {
        switch status {
        case .empty:
            isBuffering = true
        case .likelyToKeepUp, .full:
            isBuffering = false
        }
    }
    
    internal func updateBufferTime(timeRanges: [NSValue]) {
        if let timeRange = timeRanges.first?.timeRangeValue {
            self.bufferTime = timeRange.end
            self.bufferProgress = timeRange.end.seconds / duration.seconds
        }
    }
    
    enum BufferStatus {
        case empty
        case likelyToKeepUp
        case full
    }
}
