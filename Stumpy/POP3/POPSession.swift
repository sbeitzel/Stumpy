//
//  POPSession.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/3/21.
//

import Foundation
import Socket

class POPSession {
    private let socket: Socket
    private let store: MailStore

    init(socket: Socket, mailStore: MailStore) {
        self.socket = socket
        self.store = mailStore
    }

    func run() -> Void {
        print("POPSession.run() not yet implemented")
    }
}
