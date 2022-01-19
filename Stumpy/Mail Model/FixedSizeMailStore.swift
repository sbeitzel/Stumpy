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
public actor FixedSizeMailStore: MailStore, ObservableObject, Identifiable {
    public let id: String

    private let maxSize: Int
    private var messages = [MailMessage]()

    /// Creates a FixedSizeMailStore configured to hold up to the given number of messages.
    /// - Parameter size: the maximum number of messages this store will contain
    public init(size: Int, id: String = UUID().uuidString) {
        maxSize = size
        self.id = id
    }

    public func messageCount() async -> Int {
        return messages.count
    }

    /// Appends a new message to the store. If this would result in the store
    /// holding more than its maximum number of messages, the oldest message
    /// in the store will be evicted at the same time, making room for the new one.
    /// - Parameter message: the new message to add to the store
    public func add(message: MailMessage) async {
        objectWillChange.send()
        messages.append(message)
        while messages.count > maxSize {
            messages.remove(at: 0)
        }
    }

    public func list() async -> [MailMessage] {
        let messagesCopy = messages
        return messagesCopy
    }

    public func get(message: Int) async throws -> MailMessage {
        guard message >= 0 && message < messages.count else { throw MailStoreError.invalidIndex }
        return messages[message]
    }

    public func clear() async {
        objectWillChange.send()
        messages.removeAll()
    }

    public func delete(message: Int) async throws {
        guard message >= 0 && message < messages.count else { throw MailStoreError.invalidIndex }
        _ = messages.remove(at: message)
        objectWillChange.send()
    }
}
