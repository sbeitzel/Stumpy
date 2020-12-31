//
//  MemoryMessage.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/31/20.
//

import Foundation

/// An implementation of the `MailMessage` protocol that resides
/// entirely in memory.
public class MemoryMessage: MailMessage {
    private let uuid: UUID = UUID()
    private var headerDict = [String: [String]]()
    private var messageBody = ""

    public var uid: String {
        get {
            uuid.uuidString
        }
    }

    public var headers: [String : [String]] {
        get {
            headerDict
        }
    }

    public var body: String {
        get {
            messageBody
        }
    }

    public init() {}
    
    public func set(value: String, for header: String) {
        var valueArray = [String]()
        valueArray.append(value)
        headerDict[header] = valueArray
    }

    public func add(value: String, to header: String) {
        if let values = headerDict[header] {
            var updatedValues = [String]()
            updatedValues.append(contentsOf: values)
            updatedValues.append(value)
            headerDict[header] = updatedValues
        } else {
            set(value: value, for: header)
        }
    }

    public func append(line: String) {
        if (!messageBody.isEmpty && !line.isEmpty && line != "\n") {
            messageBody += "\n"
        }
        messageBody += line
    }

}
