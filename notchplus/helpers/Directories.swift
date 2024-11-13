//
//  Directories.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 06/11/24.
//

private let availableDirectories = FileManager
    .default
    .urls(for: .documentDirectory, in: .userDomainMask)

let documentsDirectory = availableDirectories.first!
let temporaryDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
