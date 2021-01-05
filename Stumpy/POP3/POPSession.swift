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
    private var state: POPState

    init(socket: Socket, mailStore: MailStore) {
        self.socket = socket
        self.store = mailStore
        self.state = POPState.AUTHORIZATION
    }

    func run() -> Void {
        print("POPSession.run() not yet implemented")
    }
}
