//
//  SessionState.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/1/21.
//

import Foundation

struct SMTPState: Equatable {
    let description: String
}

extension SMTPState {
    static let CONNECT = SMTPState(description: "CONNECT")
    static let GREET = SMTPState(description: "GREET")
    static let MAIL = SMTPState(description: "MAIL")
    static let RCPT = SMTPState(description: "RCPT")
    static let DATA_HDR = SMTPState(description: "DATA_HDR")
    static let DATA_BODY = SMTPState(description: "DATA_BODY")
    static let QUIT = SMTPState(description: "QUIT")
}
