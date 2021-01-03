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
    private let message: MailMessage

    var shouldContinue = true
    var readData: Data = Data(capacity: bufferSize)
    private var response: SMTPResponse
    private var state: SMTPState
    private var lastHeader: String

    init(socket: Socket, mailStore: MailStore) {
        self.socket = socket
        self.store = mailStore
        message = MemoryMessage()
        let request = SMTPRequest.initialRequest()
        state = request.state
        response = request.execute(with: message, on: store)
        lastHeader = ""
    }

    private func sendResponse() -> Void {
        if response.code > 0 {
            let responseMessage = "\(response.code) \(response.message)\r\n"

            do {
                try socket.write(from: responseMessage)
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    shouldContinue = false
                    return
                }
                print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                shouldContinue = false
            }
        }
    }

    private func prepareSessionLoop() -> Void {
        shouldContinue = true
        readData.removeAll(keepingCapacity: true)
        sendResponse()
        state = response.nextState
    }

    private func sessionLoop() -> Void {
        do {
            while state != SMTPState.CONNECT && shouldContinue {
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
                    let request = SMTPRequest.parseClientRequest(state: state, message: line)
                    response = request.execute(with: message, on: store)
                    store(input: request.params, message: message)
                    sendResponse()
                    state = response.nextState
                } else {
                    shouldContinue = false
                }
            }
        }
        catch let error {
            guard let socketError = error as? Socket.Error else {
                print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                shouldContinue = false
                return
            }
            print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
            shouldContinue = false
        }
    }

    private func store(input: String, message: MailMessage) -> Void {
        if !input.isEmpty {
            if response.nextState == SMTPState.DATA_HDR {
                // this is either a header ('X-Sender: foo@mx.place') or it's
                // a header continuation (that is, it's a second value that we should add
                // to the last header we processed)
                let isNewHeader = input.contains(":")
                if isNewHeader {
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
                message.append(line: input)
            }
        }
    }

    func run() -> Void {
        prepareSessionLoop()
        sessionLoop()
    }
}
