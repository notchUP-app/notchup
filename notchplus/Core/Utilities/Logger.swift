//
//  Logger.swift
//  notchplus
//
//  Created by Eduardo Monteiro on 22/03/25.
//

import Foundation

struct Logger {
    static func log(
        _ message: String,
        type: LogType,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let filename = (file as NSString).lastPathComponent
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("\(type.rawValue) [\(timestamp)] [\(filename):\(line)] \(function) -> \(message)")
    }

    static func trackMemoryUsage(
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerResult: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerResult == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0
            log(
                String(
                    format: "Memory used: %.2f MB", usedMemory),
                type: .memory,
                file: file,
                function: function,
                line: line
            )
        }
    }
}
