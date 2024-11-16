//
//  TrayDropObserver.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 04/11/24.
//

import Foundation
import Combine
import Cocoa
import OrderedCollections

public class TrayDrop: ObservableObject {
    static let shared = TrayDrop()
    
    @Published var items: OrderedSet<DropItem>
    @Published var isLoading: Int = 0
    var isEmpty: Bool { items.isEmpty }
    
    init(items: OrderedSet<DropItem> = .init(), isLoading: Int = 0) {
        self.items = items
        self.isLoading = isLoading
    }
    
    func load(_ providers: [NSItemProvider]) {
        Task {
            assert(!Thread.isMainThread)
            await MainActor.run { isLoading += 1 }
            
            guard let urls = await providers.interfaceConvert() else {
                DispatchQueue.main.asyncAndWait { isLoading -= 1 }
                print("Failed to load items")
                return
            }
            
            let dropItems = urls.map { url in
                try? DropItem(url: url)
            }.compactMap { $0 }
            
            await MainActor.run {
                dropItems.forEach { self.items.updateOrInsert($0, at: self.items.count) }
                self.isLoading -= 1
            }
            
            #if DEBUG
            print("Loaded \(dropItems.count) items")
            #endif
        }
    }
    
    func cleanExpiredFiles() {
        var inEdit = items
        let shouldCleanFiles = items.filter(\.shouldClean)
        
        for item in shouldCleanFiles {
            inEdit.remove(item)
        }
        
        items = inEdit
    }
    
    func delete(_ item: DropItem.ID) {
        guard let item = items.first(where: { $0.id == item } ) else { return }
        delete(item: item)
    }
    
    func removeAll() {
        items.forEach { delete(item: $0) }
    }
    
    private func delete(item: DropItem) {
        var inEdit = items
        
        var url = item.storageURL
        try? FileManager.default.removeItem(at: url)
        
        do {
            url = url.deletingLastPathComponent()
            while url.lastPathComponent != DropItem.mainDir, url != documentsDirectory {
                let contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
                guard contents.isEmpty else { break }
                try FileManager.default.removeItem(at: url)
                url = url.deletingLastPathComponent()
            }
        } catch {}
        
        inEdit.remove(item)
        items = inEdit
    }
}
