//
//  SMTPSessionState.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/16/22.
//

import Foundation
import Logging

class SMTPSessionState {
    private var logger: Logger

    var smtpState: SMTPState {
        get { theState }
        set {
            logger.trace("State set to \(newValue)")
            theState = newValue
        }
    }
    private var theState: SMTPState
    var workingMessage: MailMessage
    var lastHeader: String = ""
    let mailstore: MailStore
    var inputLine: String
    var command: SMTPCommand?
    var accumulatedData: String = ""

    init(with store: MailStore) {
        logger = Logger(label: "SMTPSessionState")
        logger.logLevel = .info
        logger[metadataKey: "origin"] = "[SMTP]"
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
