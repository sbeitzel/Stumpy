//
//  SMTPAction.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/1/21.
//

import Foundation

/// A command in an SMTP session
protocol SMTPAction {

    /// The representation of this action
    var asString: String { get }

    /// The state machine logic of this action. Given the parameters of the existing state,
    /// the mail store, and the current message, returns the appropriate response for the
    /// server to send to the client.
    /// - Parameters:
    ///   - state: the current state of the session
    ///   - store: the mail store on which we're operating
    ///   - message: the message being processed in the session
    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse
}

// MARK: Actions

/// The client has sent a blank line.
struct BlankLineAction: SMTPAction {
    var asString: String {
        "Blank line"
    }

    /// The client has sent a blank line. This could be the separator between message header and body,
    /// or it might be a blank line in the middle of the message body. In any other situation, this is not
    /// an expected command.
    /// - Parameters:
    ///   - state: current session state
    ///   - store: the mail store
    ///   - message: current message
    /// - Returns: the response to send to the client
    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        if SMTPState.DATA_HDR == state {
            return SMTPResponse(code: -1, message: "", nextState: SMTPState.DATA_BODY)
        } else if SMTPState.DATA_BODY == state {
            return SMTPResponse(code: -1, message: "", nextState: state)
        } else {
            return SMTPResponse(
                code: 503,
                message: "503 Bad sequence of commands: " + asString,
                nextState: state)
        }
    }
}

/// The client has initiated a connection
struct ConnectAction: SMTPAction {
    var asString: String {
        "Connect"
    }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        if SMTPState.CONNECT == state {
            return SMTPResponse(code: 220,
                                message: "220 Stumpy SMTP service ready",
                                nextState: SMTPState.GREET)
        } else {
            return SMTPResponse(code: 503,
                                message: "503 Bad sequence of commands: " + asString,
                                nextState: state)
        }
    }
}

struct DataAction: SMTPAction {
    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        if SMTPState.RCPT == state {
            return SMTPResponse(code: 354,
                                message: "354 Start mail input; end with <CRLF>.<CRLF>",
                                nextState: SMTPState.DATA_HDR)
        } else {
            return SMTPResponse(code: 503,
                                message: "503 Bad sequence of commands: " + asString,
                                nextState: state)
        }

    }

    var asString: String { "DATA" }
}

struct DataEndAction: SMTPAction {
    var asString: String { "." }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        if SMTPState.DATA_HDR == state || SMTPState.DATA_BODY == state {
            return SMTPResponse(code: 250,
                                message: "250 OK",
                                nextState: SMTPState.QUIT)
        } else {
            return SMTPResponse(code: 503,
                                message: "503 Bad sequence of commands: " + asString,
                                nextState: state)
        }
    }
}

struct HeloAction: SMTPAction {
    var asString: String { "HELO" }
    let args: String

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        if SMTPState.GREET == state {
            return SMTPResponse(code: 250,
                                message: "250 Hello \(args)",
                                nextState: SMTPState.MAIL)
        } else {
            return SMTPResponse(code: 503,
                                message: "503 Bad sequence of commands: " + asString,
                                nextState: state)
        }
    }
}

struct EhloAction: SMTPAction {
    var asString: String { "EHLO" }
    let args: String

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        if SMTPState.GREET == state {
            return SMTPResponse(code: 250,
                                message: "250-local.stumpy Hello \(args)\r\n250 OK",
                                nextState: SMTPState.MAIL)
        } else {
            return SMTPResponse(code: 503,
                                message: "503 Bad sequence of commands: " + asString,
                                nextState: state)
        }
    }
}

struct ExpnAction: SMTPAction {
    var asString: String { "EXPN" }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        SMTPResponse(code: 252,
                     message: "252 Not supported",
                     nextState: state)
    }
}

struct HelpAction: SMTPAction {
    var asString: String { "HELP" }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        SMTPResponse(code: 211,
                     message: "211 No help available",
                     nextState: state)
    }
}

struct ListAction: SMTPAction {
    private let messageIndex: Int?

    var asString: String { "LIST" }

    init(_ params: String) {
        let trimmed = params.trimmingCharacters(in: .whitespacesAndNewlines)
        messageIndex = Int(trimmed)
    }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        var result = "250 "
        let messages = store.list()
        // swiftlint:disable:next identifier_name
        if let mi = messageIndex {
            if mi > -1 && mi < messages.count-1 {
                result.append("\n-------------------------------------------\n")
                result.append(messages[mi].toString())
            }
        }
        result.append("There are \(messages.count) messages")
        return SMTPResponse(code: 250,
                            message: result,
                            nextState: SMTPState.GREET)
    }
}

struct MailAction: SMTPAction {
    var asString: String { "MAIL" }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        if SMTPState.MAIL == state || SMTPState.QUIT == state {
            return SMTPResponse(code: 250,
                                message: "250 OK",
                                nextState: SMTPState.RCPT)
        } else {
            return SMTPResponse(code: 503,
                                message: "503 Bad sequence of commands: " + asString,
                                nextState: state)
        }
    }
}

struct NoOpAction: SMTPAction {
    var asString: String { "NOOP" }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        return SMTPResponse(code: 250,
                            message: "250 OK",
                            nextState: state)
    }
}

struct QuitAction: SMTPAction {
    var asString: String { "QUIT" }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        return SMTPResponse(code: 221,
                            message: "221 Stumpy SMTP service closing transmission channel",
                            nextState: SMTPState.CONNECT)
    }
}

struct RcptAction: SMTPAction {
    var asString: String { "RCPT" }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        if SMTPState.RCPT == state {
            return SMTPResponse(code: 250,
                                message: "250 OK",
                                nextState: state)
        } else {
            return SMTPResponse(code: 503,
                                message: "503 Bad sequence of commands: " + asString,
                                nextState: state)
        }
    }
}

struct RsetAction: SMTPAction {
    var asString: String { "RSET" }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        return SMTPResponse(code: 250,
                            message: "250 OK",
                            nextState: SMTPState.GREET)
    }
}

struct UnrecognizedAction: SMTPAction {
    var asString: String { "Unrecognized command / data" }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        if SMTPState.DATA_HDR == state || SMTPState.DATA_BODY == state {
            return SMTPResponse(code: -1,
                                message: "",
                                nextState: state)
        } else {
            return SMTPResponse(code: 500,
                                message: "500 Command not recognized",
                                nextState: state)
        }
    }
}

struct VrfyAction: SMTPAction {
    var asString: String { "VRFY" }

    func getResponse(state: SMTPState, store: MailStore, message: MailMessage) -> SMTPResponse {
        return SMTPResponse(code: 252,
                            message: "252 Not Supported",
                            nextState: state)
    }
}
