//
//  SpaceManager.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 01/04/25.
//

import SwiftUI

class SpaceManager {
    static let shared = SpaceManager()
    let space: CGSSpace
    

    private init() {
        space = CGSSpace(level: 2147483647)
    }
}
