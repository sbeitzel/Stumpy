//
//  Servers.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/22/20.
//

import Foundation

class Servers {
    let smtpServer = SMTPServer(port: 4000)

    func shutdown() {
        print("\nAll servers shutting down")
        smtpServer.shutdown()
    }
}
