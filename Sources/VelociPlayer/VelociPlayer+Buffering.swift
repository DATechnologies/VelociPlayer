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
            print("[VelociPlayer]: Buffer Empty")
        case .likelyToKeepUp:
            print("[VelociPlayer]: Buffer Likely To Keep Up")
        case .full:
            print("[VelociPlayer]: Buffer Full")
        }
    }
    
    enum BufferStatus {
        case empty
        case likelyToKeepUp
        case full
    }
}
