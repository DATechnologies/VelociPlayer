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
    
    func bufferStatusChanged(to status: BufferStatus) {
        switch status {
        case .empty:
            pause()
        case .likelyToKeepUp:
            play()
        case .full:
            play()
        }
    }
    
    enum BufferStatus {
        case empty
        case likelyToKeepUp
        case full
    }
}
