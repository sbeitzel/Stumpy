//
//  POPAction.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/3/21.
//

import Foundation

/// Protocol defining how any POP action must behave. Specific actions may involve more behaviors.
/// See [RFC 1939](https://tools.ietf.org/html/rfc1939) for the basic commands, as
/// well as [RFC 2449](https://tools.ietf.org/html/rfc2449) for the extension mechanism (including the CAPA command)
/// and [RFC 5034](https://tools.ietf.org/html/rfc5034) for discussion of authentication.
protocol POPAction {
    var command: String { get }

    func getResponse(state: POPState, store: MailStore) -> POPResponse
}

/// This is an optional command to provide a slightly more secure authentication method
/// than plaintext username/password. A real POP3 server should take security seriously,
/// but Stumpy isn't intended for real use.
struct PAPOPAction: POPAction {
    var command: String { "" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        return POPResponse(code: POPResponse.OK, message: "You're okay", nextState: POPState.TRANSACTION)
    }
}

struct PCapabilityAction: POPAction {
    var command: String { "CAPA" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        let message = "List of capabilities follows\r\nUSER PASS\r\nUIDL\r\nIMPLEMENTATION Stumpy POP3 v1\r\n.\r\n"
        return POPResponse(code: POPResponse.OK, message: message, nextState: state)
    }
}

struct PInvalidAction: POPAction {
    var command: String { "" }

    let message: String

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        return POPResponse(code: POPResponse.ERROR, message: message, nextState: state)
    }
}

struct PConnectAction: POPAction {

    let sessionID: String

    let hostname: String

    var command: String { "" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        if state == POPState.AUTHORIZATION {
            let now = Date()
            // string of the form "<sessionID.timestamp@host>"
            // If we were writing a server that actually implemented multi-mailbox and user security
            // then we'd care more about this. The one thing we should care about is that this string
            // is different for each request.
            let message = "Stumpy POP3 server ready <\(sessionID).\(now.timeIntervalSinceReferenceDate)@\(hostname)>\r\n"
            return POPResponse(code: POPResponse.OK, message: message, nextState: state)
        } else {
            return PInvalidAction(message: "").getResponse(state: state, store: store)
        }
    }
}

struct PDeleteAction: POPAction {
    let messageIndex: Int?

    var command: String { "DELE" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        if state != POPState.TRANSACTION {
            return PInvalidAction(message: "Not allowed in this state").getResponse(state: state, store: store)
        }
        if let mi = messageIndex {
            if (mi > 0 && mi <= store.messageCount) {
                store.delete(message: mi-1)
            } // TODO: should this return an error if the index is not okay? Check the RFC.
        }
        return POPResponse(code: POPResponse.OK, message: "message deleted", nextState: POPState.TRANSACTION)
    }
}

struct PListAction: POPAction {

    let messageIndex: Int?

    var command: String { "LIST" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        if state != POPState.TRANSACTION {
            return PInvalidAction(message: "Not allowed in this state").getResponse(state: state, store: store)
        }
        if let mi = messageIndex {
            if mi < store.messageCount {
                let message = store.get(message: mi)
                return POPResponse(code: POPResponse.OK, message: scanListing(mi + 1, message), nextState: POPState.TRANSACTION)
            } else {
                return POPResponse(code: POPResponse.ERROR, message: "No such message", nextState: POPState.TRANSACTION)
            }
        } else {
            // build a scan listing for all the messages in the store
            let messages = store.list()
            let count = messages.count
            var allListings = "\(count) messages\r\n"
            for index in 0 ..< count {
                allListings.append(scanListing(index + 1, messages[index]))
            }
            allListings.append(".\r\n")
            return POPResponse(code: POPResponse.OK, message: allListings, nextState: POPState.TRANSACTION)
        }
    }

    private func scanListing(_ index: Int, _ message: MailMessage) -> String {
        let messageBytes = message.toString().lengthOfBytes(using: .utf8)
        return "\(index) \(messageBytes)\r\n"
    }
}

struct PNoOpAction: POPAction {
    var command: String { "NOOP" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        return POPResponse(code: POPResponse.OK, message: "", nextState: POPState.TRANSACTION)
    }
}

struct PPasswordAction: POPAction {
    var command: String { "PASS" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        if state != POPState.AUTHORIZATION {
            return PInvalidAction(message: "Not allowed in this state").getResponse(state: state, store: store)
        }
        return POPResponse(code: POPResponse.OK, message: "mailbox ready", nextState: POPState.TRANSACTION)
    }
}

struct PQuitAction: POPAction {
    var command: String { "QUIT" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        return POPResponse(code: POPResponse.OK, message: "Goodbye", nextState: POPState.QUIT)
    }
}

/// If this were a real POP3 server, this action would undelete any messages marked for deletion during
/// this session. Rather that do that, we're just saying, sure, it's been undeleted. This might (probably will)
/// confuse email clients that try to be clever about maintaining state on their side.
struct PResetAction: POPAction {
    var command: String { "RSET" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        if state != POPState.TRANSACTION {
            return PInvalidAction(message: "Not allowed in this state").getResponse(state: state, store: store)
        }
        return POPResponse(code: POPResponse.OK, message: "Stumpy doesn't really undelete", nextState: POPState.TRANSACTION)
    }
}

struct PRetrieveAction: POPAction {

    let messageIndex: Int?

    var command: String { "RETR" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        if state != POPState.TRANSACTION {
            return PInvalidAction(message: "Not allowed in this state").getResponse(state: state, store: store)
        }
        if let mi = messageIndex {
            let message = store.get(message: mi)
            let messageString = message.byteStuff()
            let bytes = messageString.maximumLengthOfBytes(using: .utf8)
            let responseString = "\(bytes) octets\r\n\(messageString)"
            return POPResponse(code: POPResponse.OK, message: responseString, nextState: POPState.TRANSACTION)
        } else {
            return POPResponse(code: POPResponse.ERROR, message: "No such message", nextState: POPState.TRANSACTION)
        }
    }
}

struct PStatusAction: POPAction {
    var command: String { "STAT" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        if state != POPState.TRANSACTION {
            return PInvalidAction(message: "Not allowed in this state").getResponse(state: state, store: store)
        }
        let messages = store.list()
        var size: UInt64 = 0
        for message in messages {
            size += UInt64(message.byteStuff().maximumLengthOfBytes(using: .utf8))
        }
        let responseMessage = "\(messages.count) \(size)"
        return POPResponse(code: POPResponse.OK, message: responseMessage, nextState: POPState.TRANSACTION)
    }
}

/*
 If the POP3 server issues a positive response, then the
              response given is multi-line.  After the initial +OK, the
              POP3 server sends the headers of the message, the blank
              line separating the headers from the body, and then the
              number of lines of the indicated message's body, being
              careful to byte-stuff the termination character (as with
              all multi-line responses).

              Note that if the number of lines requested by the POP3
              client is greater than than the number of lines in the
              body, then the POP3 server sends the entire message.
 */
struct PTopAction: POPAction {
    var command: String { "TOP" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        return PQuitAction().getResponse(state: state, store: store)
    }
}

/// With an argument (a message index), respond with OK, message index, and message uuid.
/// With no argument, respond with OK, crlf, then message index and message uuid and crlf for each message.
/// If the argument isn't a valid message index, respond with ERR.
struct PUIDLAction: POPAction {

    let messageIndex: Int?

    var command: String { "UIDL" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        if state != POPState.TRANSACTION {
            return PInvalidAction(message: "Not allowed in this state").getResponse(state: state, store: store)
        }
        if let mi = messageIndex {
            // one message
            if mi < store.messageCount {
                // NOTE - POP starts indexing messages at 1!
                let message = store.get(message: mi - 1)
                let responseMessage = "\(mi) \(message.uid)\r\n.\r\n"
                return POPResponse(code: POPResponse.OK, message: responseMessage, nextState: POPState.TRANSACTION)
            } else {
                return POPResponse(code: POPResponse.ERROR, message: "No such message", nextState: POPState.TRANSACTION)
            }
        } else {
            // all of them
            let messages = store.list()
            var responseMessage = "\r\n"
            for index in 0 ..< messages.count {
                let message = messages[index]
                responseMessage.append("\(index + 1) \(message.uid)")
            }
            responseMessage.append(".\r\n")
            return POPResponse(code: POPResponse.OK, message: responseMessage, nextState: POPState.TRANSACTION)
        }
    }
}

struct PUserAction: POPAction {
    var command: String { "USER" }

    func getResponse(state: POPState, store: MailStore) -> POPResponse {
        if state == POPState.AUTHORIZATION {
            return POPResponse(code: POPResponse.OK, message: "", nextState: POPState.AUTHORIZATION)
        }
        return PInvalidAction(message: "Not allowed in this state").getResponse(state: state, store: store)
    }
}

