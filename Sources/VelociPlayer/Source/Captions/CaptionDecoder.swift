//
//  CaptionDecoder.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 3/23/22.
//

import Foundation
import CoreMedia

public enum CaptionDecoder {
    
    private static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss,SSS"
        return timeFormatter
    }()
    
    private static let baseDate: Date = {
        let baseTimeString = "00:00:00,000"
        return timeFormatter.date(from: baseTimeString) ?? Date()
    }()
    
    private static let srtRegexPattern = #"(?<id>\d+)\R(?<startTime>\d{2}:\d{2}:\d{2},\d{3}) --> (?<endTime>\d{2}:\d{2}:\d{2},\d{3})\R(?<captionText>\X+?\R\R|\X+?$)"#
    
    /// Convert an SRT string to an array of `Caption`
    /// - Parameter srt: A string representation of an SRT file.
    /// - Returns: An array of the decoded captions from the provided SRT string.
    public static func getCaptions(for srt: String) -> [Caption] {
        let srtString = srt + "\n\n" // Some SRT files end early, so this adds some new lines to allow the regex to pick up the last caption
        var captions = [Caption]()
        
        let regex = try? NSRegularExpression(pattern: srtRegexPattern, options: [.anchorsMatchLines])
        let srtRange = NSRange(srtString.startIndex ..< srtString.endIndex, in: srtString)
        
        // Loop over all matches for our regex.
        regex?.enumerateMatches(in: srtString, options: [], range: srtRange) { match, _, _ in
            guard let match = match else { return }
            var captures = [String: String]()
            
            // Find all named captures in the matched regex
            for captureName in ["id", "startTime", "endTime", "captionText"] {
                let matchRange = match.range(withName: captureName)
                
                if let substringRange = Range(matchRange, in: srtString) {
                    let capture = String(srtString[substringRange])
                    captures[captureName] = capture
                }
            }
            
            if let caption = makeCaption(for: captures) {
                captions.append(caption)
            }
        }
        
        // Even though they definitely should be sorted, sort the captions to verify.
        var sortedCaptions = captions.sorted { firstCaption, secondCaption in
            return firstCaption.id ?? 0 < secondCaption.id ?? 0
        }
        
        // Go back through the array and fill in any time gaps with empty captions.
        for index in 0 ..< sortedCaptions.count {
            let caption = sortedCaptions[index]
            if index == 0 && caption.displayRange.lowerBound != VPTime.zero {
                let startCaption = Caption(id: nil, displayRange: VPTime.zero ... caption.displayRange.lowerBound, text: nil)
                sortedCaptions.insert(startCaption, at: 0)
            } else if index != sortedCaptions.endIndex - 1 {
                let nextCaption = sortedCaptions[index + 1]
                if caption.displayRange.upperBound < nextCaption.displayRange.lowerBound {
                    let emptyCaption = Caption(id: nil, displayRange: caption.displayRange.upperBound ... nextCaption.displayRange.lowerBound, text: nil)
                    sortedCaptions.insert(emptyCaption, at: index + 1)
                }
            }
        }
        
        return sortedCaptions
    }
    
    private static func makeCaption(for captures: [String: String]) -> Caption? {
        guard let idString = captures["id"],
              let id = Int(idString),
              let startTimeString = captures["startTime"],
              let startDate = timeFormatter.date(from: startTimeString),
              let endTimeString = captures["endTime"],
              let endDate = timeFormatter.date(from: endTimeString),
              let captionText = captures["captionText"]
        else {
            return nil
        }
        
        // Time scale must be 10,000 so we don't ignore the milliseconds
        let startTimeInterval = startDate.timeIntervalSince(baseDate)
        let startTime = VPTime(seconds: startTimeInterval, preferredTimescale: 10_000)
        
        let endTimeInterval = endDate.timeIntervalSince(baseDate)
        let endTime = VPTime(seconds: endTimeInterval, preferredTimescale: 10_000)
        
        let cutCaptionText = captionText.trimmingCharacters(in: .newlines)
        
        return Caption(id: id, displayRange: startTime ... endTime, text: cutCaptionText)
    }
}
