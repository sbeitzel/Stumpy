//
//  SMTPSession.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/1/21.
//

import Foundation
import Socket

class SMTPSession {
    private static let bufferSize = 4096

    private let socket: Socket
    private let store: MailStore
    private var message: MailMessage

    var shouldContinue = true
    var readData: Data = Data(capacity: bufferSize)
    private var response: SMTPResponse
    private var state: SMTPState
    private var lastHeader: String

    private func log(_ message: String) {
        print("[SMTPSession] \(message)")
    }

    init(socket: Socket, mailStore: MailStore) {
        self.socket = socket
        self.store = mailStore
        message = MemoryMessage()
        let request = SMTPRequest.initialRequest()
        state = request.state
        response = request.execute(with: message, on: store)
        lastHeader = ""
    }

    private func sendResponse() {
        if response.code > 0 {
            let responseMessage = "\(response.code) \(response.message)\r\n"
            log("Sending response: \(responseMessage)")
            do {
                try socket.write(from: responseMessage)
            } catch let error {
                guard let socketError = error as? Socket.Error else {
                    log("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    shouldContinue = false
                    return
                }
                log("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                shouldContinue = false
            }
        }
    }

    private func prepareSessionLoop() {
        shouldContinue = true
        readData.removeAll(keepingCapacity: true)
        sendResponse()
        state = response.nextState
    }

    private func sessionLoop() {
        do {
            while state != SMTPState.CONNECT && shouldContinue {
                // read a line from the client
                let bytesRead = try socket.read(into: &readData)
                if bytesRead > 0 {
                    let lines = readData.lines()
                    // after we read the lines, we need to clear the buffer
                    readData.removeAll(keepingCapacity: true)
                    for line in lines {
                        let request = SMTPRequest.parseClientRequest(state: state, message: line)
                        response = request.execute(with: message, on: store)
                        store(input: request.params, message: message)
                        sendResponse()
                        state = response.nextState
                        maybeSaveMessage()
                    }
                } else {
                    shouldContinue = false
                }
            }
        } catch let error {
            guard let socketError = error as? Socket.Error else {
                log("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                shouldContinue = false
                return
            }
            log("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
            shouldContinue = false
        }
    }

    private func maybeSaveMessage() {
        if state == SMTPState.QUIT {
            guard message.headers["Message-ID"] != nil else {
                return
            }
            store.add(message: message)
            message = MemoryMessage() // TODO: use a factory to construct new messages and pass the factory to the session initializer
        }
    }

    private func store(input: String, message: MailMessage) {
        if !input.isEmpty {
            log("storing input to message: \(input)")
            if response.nextState == SMTPState.DATA_HDR {
                log("storing a header")
                // this is either a header ('X-Sender: foo@mx.place') or it's
                // a header continuation (that is, it's a second value that we should add
                // to the last header we processed)
                let isNewHeader = input.contains(":")
                if isNewHeader {
                    log("new header")
                    let start = input.firstIndex(of: ":")
                    let header = String(input[input.startIndex ..< start!])
                    var value: String
                    value = String(input[start! ..< input.endIndex])
                    value.removeFirst()
                    message.set(value: value, for: header)
                    lastHeader = header
                } else {
                    let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    message.appendHeader(value: value, to: lastHeader)
                }
            } else if response.nextState == SMTPState.DATA_BODY {
                log("appending line to message")
                message.append(line: input)
            }
        } else {
            log("no input stored to message")
        }
    }

    func run() {
        prepareSessionLoop()
        sessionLoop()
    }
}
