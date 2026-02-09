//
//  Ext+FileProvider.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/8.
//  Modified by Eduardo Monteiro on 2024/11/15
//

import Cocoa
import Foundation
import UniformTypeIdentifiers

extension NSItemProvider {
    private func duplicateToStorage(_ url: URL?) throws -> URL? {
        guard let url else { return nil }
        let temp = temporaryDirectory
            .appendingPathComponent("TemporaryDrop")
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(url.lastPathComponent)
        try FileManager.default.createDirectory(
            at: temp.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(at: url, to: temp)
        return temp
    }
    
    func convertToFilePath() async throws -> URL? {
        if let url = try? await loadURL() {
            return try duplicateToStorage(url)
        } else if let fileRepresentation = try? await loadInPlaceFileRepresentation() {
            return try duplicateToStorage(fileRepresentation)
        }
        
        return nil
    }
    
    private func loadURL() async throws -> URL? {
        return try await withCheckedThrowingContinuation { continuation in
            _ = loadObject(ofClass: URL.self) { item, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: item)
                }
            }
        }
    }
    
    private func loadInPlaceFileRepresentation() async throws -> URL? {
        return try await withCheckedThrowingContinuation { continuation in
            loadInPlaceFileRepresentation(forTypeIdentifier: UTType.data.identifier) { input, success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: input)
                }
            }
        }
    }
    
}

extension [NSItemProvider] {
    func interfaceConvert() async -> [URL]? {
        var urls: [URL] = []
        var failed = false
        
        for provider in self {
            do {
                if let url = try await provider.convertToFilePath() {
                    urls.append(url)
                } else {
                    failed = true
                }
            } catch {
                failed = true
            }
        }
        
        if failed || urls.count != count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSAlert.popError(NSLocalizedString("One or more files failed to load", comment: ""))
            }
            return nil
        }
        
        return urls
    }
}
