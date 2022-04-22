//
//  Caption.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 3/23/22.
//

import Foundation
import CoreMedia

public struct Caption {
    public let id: Int?
    public let displayRange: ClosedRange<CMTime>
    public let text: String?
}
