//
//  SMTPSessionState.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/16/22.
//

import Foundation

class SMTPSessionState {
    var smtpState: SMTPState
    var workingMessage: MailMessage
    var lastHeader: String = ""
    let mailstore: MailStore
    var inputLine: String
    var command: SMTPCommand?

    init(with store: MailStore) {
        inputLine = ""
        mailstore = store
        workingMessage = MemoryMessage()
        smtpState = .connect
    }
}

struct SMTPCommand {
    let action: SMTPAction
    let parameters: String
}
