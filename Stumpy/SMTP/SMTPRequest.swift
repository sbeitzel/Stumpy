//
//  SMTPRequest.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/1/21.
//

import Foundation

struct SMTPRequest {

    /// The action to be performed
    var action: SMTPAction

    /// The current state of the session
    var state: SMTPState

    /// Any arguments provided for the action
    var params: String

    /// Create the first request for a client session
    /// - Returns: The initial request
    static func initialRequest() -> SMTPRequest {
        SMTPRequest(action: ConnectAction(), state: SMTPState.CONNECT, params: "")
    }

    static func parseClientRequest(state: SMTPState, message: String) -> SMTPRequest {
        switch state {
        case .DATA_HDR:
            if message == "." {
                return SMTPRequest(action: DataEndAction(), state: state, params: "")
            } else if message.isEmpty {
                return SMTPRequest(action: BlankLineAction(), state: state, params: "")
            } else {
                return SMTPRequest(action: UnrecognizedAction(), state: state, params: message)
            }
        case .DATA_BODY:
            if message == "." {
                return SMTPRequest(action: DataEndAction(), state: state, params: "")
            } else if message.isEmpty {
                return SMTPRequest(action: UnrecognizedAction(), state: state, params: "\n")
            } else {
                return SMTPRequest(action: UnrecognizedAction(), state: state, params: message)
            }
        default:
            let su = message.uppercased()
            var action: SMTPAction
            var params = ""
            if su.hasPrefix("EHLO ") {
                action = EhloAction()
                params = message
                params.removeFirst(5)
            } else if su.hasPrefix("HELO") {
                action = EhloAction()
            } else if su.hasPrefix("MAIL FROM:") {
                action = MailAction()
                params = message
                params.removeFirst(10)
            } else if su.hasPrefix("RCPT TO:") {
                action = RcptAction()
                params = message
                params.removeFirst(8)
            } else if su.hasPrefix("DATA") {
                action = DataAction()
            } else if su.hasPrefix("QUIT") {
                action = QuitAction()
            } else if su.hasPrefix("RSET") {
                action = RsetAction()
            } else if su.hasPrefix("NOOP") {
                action = NoOpAction()
            } else if su.hasPrefix("EXPN") {
                action = ExpnAction()
            } else if su.hasPrefix("VRFY") {
                action = VrfyAction()
            } else if su.hasPrefix("HELP") {
                action = HelpAction()
            } else if su.hasPrefix("LIST") {
                params = message
                params.removeFirst(4)
                action = ListAction(params)
            } else {
                action = UnrecognizedAction()
            }

            return SMTPRequest(action: action, state: state, params: params)
        }
    }

    /// Compute the appropriate response for this request
    /// - Parameters:
    ///   - message: the message being worked on
    ///   - store: the mailstore being used
    /// - Returns: the result of performing this operation
    func execute(with message: MailMessage, on store: MailStore) -> SMTPResponse {
        action.getResponse(state: state, store: store, message: message)
    }
}
