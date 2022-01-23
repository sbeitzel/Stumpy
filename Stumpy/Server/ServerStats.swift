//
//  ServerStats.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/22/22.
//

import Foundation

class ServerStats: ObservableObject {
    private var numConnections: Int = 0
    private let connectionLock = NSLock()
    var connections: Int {
        defer { connectionLock.unlock() }
        connectionLock.lock()
        return numConnections
    }

    func increaseConnectionCount() {
        defer { connectionLock.unlock() }
        connectionLock.lock()
        numConnections += 1
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    func decreaseConnectionCount() {
        defer { connectionLock.unlock() }
        connectionLock.lock()
        numConnections -= 1
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
