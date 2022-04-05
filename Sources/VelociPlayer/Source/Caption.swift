//
//  Caption.swift
//  VelociPlayer
//
//  Created by Ethan Humphrey on 3/23/22.
//

import Foundation
import CoreMedia

public struct Caption {
    let id: Int?
    let displayRange: ClosedRange<CMTime>
    let text: String?
}
