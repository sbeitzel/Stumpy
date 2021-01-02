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

    let socket: Socket

    var shouldContinue = true
    var readData: Data = Data(capacity: bufferSize)

    init(socket: Socket) {
        self.socket = socket
    }

    private func prepareSessionLoop() -> Void {
        shouldContinue = true
        readData.removeAll(keepingCapacity: true)
    }

    private func sessionLoop() -> Void {

    }

    func run() -> Void {
        prepareSessionLoop()
        sessionLoop()
    }
}
