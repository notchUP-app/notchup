//
//  DataTypeExtensions.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 03/11/24.
//

import Foundation

extension CGFloat {
    @inline(__always) @inlinable var intround: Int { rounded().i }
    
    @inline(__always) @inlinable var i: Int { Int(self) }
    
    var evenInt: Int {
        let x = intround
        return x + x % 2
    }
}

extension Double {
    @inline(__always) @inlinable var intround: Int { rounded().i }
    
    @inline(__always) @inlinable var i: Int { Int(self) }
    
    var evenInt: Int {
        let x = intround
        return x + x % 2
    }
}

extension Int {
    var s: String { String(self) }
    
    var d: Double { Double(self) }
}

extension NSSize {
    var s: String { "\(width)x\(height)" }
    
    var aspectRatio: Double { width / height }
    
    func scaled(by factor: Double) -> CGSize {
        CGSize(width: (width * factor).evenInt, height: (height * factor).evenInt)
    }
}
