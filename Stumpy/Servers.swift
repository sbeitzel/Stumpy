//
//  Servers.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/22/20.
//

import Foundation

class Servers {
    let smtpServer: SMTPServer
    let popServer: POPServer

    private var mailStore: MailStore

    init() {
        mailStore = FixedSizeMailStore(size: 100)
        smtpServer = SMTPServer(port: 4000, store: mailStore)
        popServer = POPServer(port: 4001, store: mailStore)
    }

    func shutdown() {
        print("\nAll servers shutting down")
        smtpServer.shutdown()
        popServer.shutdown()
    }
}
