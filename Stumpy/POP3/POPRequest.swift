//
//  POPRequest.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/4/21.
//

import Foundation

struct POPRequest {
    let action: POPAction

    let state: POPState

    static func initialRequest(sessionID: String, hostname: String) -> POPRequest {
        return POPRequest(action: PConnectAction(sessionID: sessionID,
                                                 hostname: hostname),
                          state: POPState.AUTHORIZATION)
    }

    static func parseClientRequest(state: POPState, line: String) -> POPRequest {
        let action = parseInput(state: state, line: line)
        return POPRequest(action: action, state: state)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private static func parseInput(state: POPState, line: String) -> POPAction {
        print("POP server received request: \(line)")
        let ucLine = line.uppercased()
        switch state {
        case POPState.AUTHORIZATION:
            if ucLine.hasPrefix("USER") {
                return PUserAction()
            } else if ucLine.hasPrefix("PASS") {
                return PPasswordAction()
            } else if ucLine.hasPrefix("APOP") {
                return PAPOPAction()
            } else if ucLine.hasPrefix("QUIT") {
                return PQuitAction()
            } else if ucLine.hasPrefix("CAPA") {
                return PCapabilityAction()
            } else {
                return PInvalidAction(message: "Invalid command for state \(state.description)")
            }
        case POPState.TRANSACTION:
            if ucLine.hasPrefix("CAPA") {
                return PCapabilityAction()
            } else if ucLine.hasPrefix("STAT") {
                return PStatusAction()
            } else if ucLine.hasPrefix("LIST") {
                var params = line
                params.removeFirst(4)
                let messageIndex = Int(params.trimmingCharacters(in: .whitespacesAndNewlines))
                return PListAction(messageIndex: messageIndex)
            } else if ucLine.hasPrefix("RETR") {
                var params = line
                params.removeFirst(4)
                return PRetrieveAction(messageIndex: Int(params.trimmingCharacters(in: .whitespacesAndNewlines)))
            } else if ucLine.hasPrefix("DELE") {
                var params = line
                params.removeFirst(4)
                return PDeleteAction(messageIndex: Int(params.trimmingCharacters(in: .whitespacesAndNewlines)))
            } else if ucLine.hasPrefix("NOOP") {
                return PNoOpAction()
            } else if ucLine.hasPrefix("QUIT") {
                return PQuitAction()
            } else if ucLine.hasPrefix("RSET") {
                return PResetAction()
            } else if ucLine.hasPrefix("TOP") {
                return PTopAction()
            } else if ucLine.hasPrefix("UIDL") {
                var params = line
                params.removeFirst(4)
                return PUIDLAction(messageIndex: Int(params.trimmingCharacters(in: .whitespacesAndNewlines)))
            } else {
                return PInvalidAction(message: "Invalid command for state \(state.description)")
            }
        default:
            return PQuitAction()
        }
    }
}
