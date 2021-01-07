//
//  POPSession.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/3/21.
//

import Foundation
import Socket

class POPSession {
    private let socket: Socket
    private let store: MailStore
    private let sessionID: String
    private var state: POPState
    private var response: POPResponse

    init(socket: Socket, mailStore: MailStore) {
        self.sessionID = UUID().uuidString
        self.socket = socket
        self.store = mailStore
        self.state = POPState.AUTHORIZATION
        self.response = POPRequest.initialRequest(sessionID: self.sessionID, hostname: "stumpy.local").action.getResponse(state: state, store: store)
    }

    private func sendResponse() {
        var line = "\(response.code.description) \(response.message)"
        if !line.hasSuffix("\r\n") {
            line.append("\r\n")
        }
        print("POP server sending response: \(line)")
        do {
            try socket.write(from: line)
        } catch let error {
            guard let socketError = error as? Socket.Error else {
                print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                state = POPState.QUIT
                return
            }
            print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
            state = POPState.QUIT
        }
    }

    func run() {
        sendResponse()
        state = response.nextState
        var readData: Data = Data(capacity: 4096) // this is probably excessive

        do {
            while state != POPState.QUIT {
                // read a line from the client
                let bytesRead = try socket.read(into: &readData)
                if bytesRead > 0 {
                    guard let line = String(data: readData, encoding: .utf8) else {
                        print("Error decoding client request.")
                        readData.count = 0
                        break
                    }
                    // after we read the line, we need to clear the buffer
                    readData.removeAll(keepingCapacity: true)
                    let request = POPRequest.parseClientRequest(state: state, line: line)
                    response = request.action.getResponse(state: state, store: store)
                    sendResponse()
                    state = response.nextState
                } else {
                    state = POPState.QUIT
                }
            }
        } catch let error {
            guard let socketError = error as? Socket.Error else {
                print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                state = POPState.QUIT
                return
            }
            print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
            state = POPState.QUIT
        }
    }
}
