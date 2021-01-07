//
//  MailStore.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/31/20.
//

import Foundation

/// Protocol declaring how a mail storage implementation must behave.
public protocol MailStore {
    /// The number of messages currently held in the mail store
    var messageCount: Int { get }

    /// Add a message to the mail store. The location within the store is
    /// up to the implementation.
    func add(message: MailMessage)

    /// Retrieve all messages currently in the store as an array. The order
    /// of the items within the array is stable over time.
    func list() -> [MailMessage]

    /// Retrieve a single message from the mail store, at a particular index.
    ///
    /// This is equivalent to `list()[message]`, but allows the implementation
    /// to avoid generating the entire list as an optimization.
    func get(message: Int) -> MailMessage

    /// Remove all messages from the mail store
    func clear()

    /// Remove a single message from the mail store, specified by a particular index.
    func delete(message: Int)
}
