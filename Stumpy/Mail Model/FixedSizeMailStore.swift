//
//  FixedSizeMailStore.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/31/20.
//

import Foundation

class FixedSizeMailStore: MailStore {
    private let maxSize: Int
    private var messages = [MailMessage]()
    private let messagesQueue = DispatchQueue(label: "com.qbcps.Stumpy.fixedSizeMailStore")

    init(size: Int) {
        maxSize = size
    }

    var messageCount: Int {
        get {
            messagesQueue.sync {
                return messages.count
            }
        }
    }

    func add(message: MailMessage) {
        messagesQueue.sync {
            messages.append(message)
            while messages.count > maxSize {
                messages.remove(at: 0)
            }
        }
    }

    func list() -> [MailMessage] {
        messagesQueue.sync {
            let messagesCopy = messages
            return messagesCopy
        }
    }

    func get(message: Int) -> MailMessage {
        messagesQueue.sync {
            return messages[message]
        }
    }

    func clear() {
        messagesQueue.sync {
            messages.removeAll()
        }
    }

    func delete(message: Int) {
        messagesQueue.sync {
            _ = messages.remove(at: message)
        }
    }

}
