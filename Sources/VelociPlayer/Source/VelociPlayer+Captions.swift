//
//  VelociPlayer+Captions.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 4/5/22.
//

import Foundation
import CoreMedia

extension VelociPlayer {
    
    /// Decodes a provided SRT file and prepares VelociPlayer to provide captions through playback.
    /// - Parameter srtData: An SRT file represented as `Data`.
    public func setUpCaptions(for srtData: Data) throws {
        guard let srtString = String(data: srtData, encoding: .utf8) else {
            throw VelociPlayerError.invalidSRT
        }
        setUpCaptions(for: srtString)
    }
    
    /// Decodes a provided SRT file and prepares VelociPlayer to provide captions through playback.
    /// - Parameter srtString: An SRT file represented as a `String`.
    public func setUpCaptions(for srtString: String) throws {
        let captions = CaptionDecoder.getCaptions(for: srtString)
        guard !captions.isEmpty else {
            throw VelociPlayerError.invalidSRT
        }
        currentCaption = nil
        allCaptions = captions
    }
    
    /// Removes any active captions.
    public func removeCaptions() {
        currentCaption = nil
        allCaptions = nil
    }
    
    internal func updateCaptions(time: CMTime) {
        // Make sure we don't perform extraneous searches if we know the current caption should be displayed.
        guard let allCaptions = allCaptions,
              !(currentCaption?.displayRange.contains(time) ?? false)
        else {
            return
        }
        
        // Additionally, make sure we don't search if the current time is past the last caption.
        guard time <= allCaptions.last?.displayRange.upperBound ?? CMTime.zero else {
            if currentCaption != nil {
                currentCaption = nil
            }
            return
        }
        
        // Search for the current caption using binary search to be as efficient as possible.
        currentCaption = captionBinarySearch(for: time)
        print(currentCaption as Any)
    }
    
    internal func captionBinarySearch(for time: CMTime, bottom: Int = 0, top: Int? = nil) -> Caption? {
        guard let allCaptions = allCaptions else { return nil }
        
        let upperBound = top ?? allCaptions.count
        guard bottom < upperBound else {
            return nil
        }
        
        let mid = bottom + ((upperBound - bottom) / 2)
        let range = allCaptions[mid].displayRange
        
        if range.contains(time) {
            return allCaptions[mid]
        } else if range.lowerBound > time {
            return captionBinarySearch(for: time, bottom: bottom, top: mid)
        } else if range.upperBound < time {
            return captionBinarySearch(for: time, bottom: mid + 1, top: upperBound)
        }
        return nil
    }
    
}
