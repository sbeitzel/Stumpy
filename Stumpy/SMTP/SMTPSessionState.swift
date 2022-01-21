//
//  SMTPSessionState.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/16/22.
//

import Foundation

class SMTPSessionState {
    var smtpState: SMTPState {
        get { theState }
        set {
            print("State set to \(newValue)")
            theState = newValue
        }
    }
    private var theState: SMTPState
    var workingMessage: MailMessage
    var lastHeader: String = ""
    let mailstore: MailStore
    var inputLine: String
    var command: SMTPCommand?

    init(with store: MailStore) {
        inputLine = ""
        mailstore = store
        workingMessage = MemoryMessage()
        theState = .connect
    }
}

struct SMTPCommand {
    let action: SMTPAction
    let parameters: String
}
