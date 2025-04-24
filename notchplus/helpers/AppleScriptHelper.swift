//
//  AppleScriptHelper.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 09/04/25.
//

import Foundation

class AppleScriptHelper {
    class func execute(_ scriptText: String) -> NSAppleEventDescriptor? {
        let script = NSAppleScript(source: scriptText)
        var error: NSDictionary?
        
        guard let result = script?.executeAndReturnError(&error) else {
            Logger.log("AppleScript error: \(String(describing: error))", type: .error)
            return nil
        }
        
        return result
    }
    
    class func executeVoid(_ scriptText: String) {
        _ = execute(scriptText)
    }
        
}
