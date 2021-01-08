//
//  FixedSizeMailStore.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/31/20.
//

import Foundation

/// A `MailStore` implementation that holds up to a specified number of messages
/// in memory. Once the limit is reached, adding a new message will evict the oldest
/// message.
public class FixedSizeMailStore: MailStore, ObservableObject, Identifiable {
    public let id: String

    @Published public var numberOfMessages: Int = 0

    private let maxSize: Int
    private var messages = [MailMessage]()
    private let messagesQueue = DispatchQueue(label: "com.qbcps.Stumpy.fixedSizeMailStore")

    /// Creates a FixedSizeMailStore configured to hold up to the given number of messages.
    /// - Parameter size: the maximum number of messages this store will contain
    public init(size: Int) {
        maxSize = size
        id = UUID().uuidString
    }

    public var messageCount: Int {
        messagesQueue.sync {
            return messages.count
        }
    }

    /// Appends a new message to the store. If this would result in the store
    /// holding more than its maximum number of messages, the oldest message
    /// in the store will be evicted at the same time, making room for the new one.
    /// - Parameter message: the new message to add to the store
    public func add(message: MailMessage) {
        messagesQueue.sync {
            objectWillChange.send()
            messages.append(message)
            while messages.count > maxSize {
                messages.remove(at: 0)
            }
            numberOfMessages = messages.count
        }
    }

    public func list() -> [MailMessage] {
        messagesQueue.sync {
            let messagesCopy = messages
            return messagesCopy
        }
    }

    public func get(message: Int) -> MailMessage {
        messagesQueue.sync {
            return messages[message]
        }
    }

    public func clear() {
        messagesQueue.sync {
            objectWillChange.send()
            messages.removeAll()
            numberOfMessages = messages.count
        }
    }

    public func delete(message: Int) {
        messagesQueue.sync {
            objectWillChange.send()
            _ = messages.remove(at: message)
            numberOfMessages = messages.count
        }
    }

}
