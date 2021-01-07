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
    static let DATA_HDR = SMTPState(description: "DATA_HDR") // swiftlint:disable:this identifier_name
    static let DATA_BODY = SMTPState(description: "DATA_BODY") // swiftlint:disable:this identifier_name
    static let QUIT = SMTPState(description: "QUIT")
}
