//
//  Data-Lines.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/5/21.
//

import Foundation

extension Data {
    public func lines() -> [String] {
        guard let buffer = String(data: self, encoding: .utf8) else {
            return [String]()
        }

        var lines = [String]()
        var line = ""

        for (_, c) in buffer.enumerated() {
            if c == "\r\n" {
                lines.append(line)
                line = ""
            } else {
                line.append(c)
            }
        }
        if !line.isEmpty {
            lines.append(line)
        }

        return lines
    }
}
