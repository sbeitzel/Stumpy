//  Created by Stephen Beitzel on 12/21/20.
//

import Foundation
import Socket
import Dispatch

class SMTPServer: ObservableObject {

    private static let quitCommand: String = "QUIT"
    private static let bufferSize = 4096

    private var port: Int
    var serverPort: Int {
        get {
            port
        }
        set(newPort) {
            if continueRunning == false {
                port = newPort
            } else {
                print("Attempted to change port while server is running! Port not changed.")
            }
        }
    }
    private var listenSocket: Socket? = nil
    private var continueRunningValue = false
    private var connectedSockets = [Int32: Socket]()
    private let socketLockQueue = DispatchQueue(label: "com.kitura.serverSwift.socketLockQueue")
    var continueRunning: Bool {
        set(newValue) {
            objectWillChange.send()
            socketLockQueue.sync {
                print("Setting SMTP continueRunning to \(newValue)")
                self.continueRunningValue = newValue
            }
        }
        get {
            return socketLockQueue.sync {
                self.continueRunningValue
            }
        }
    }

    init(port: Int) {
        self.port = port
    }

    deinit {
        // Close all open sockets...
        for socket in connectedSockets.values {
            socket.close()
        }
        self.listenSocket?.close()
    }

    func run() {
        continueRunning = true
        let queue = DispatchQueue.global(qos: .userInteractive)

        queue.async { [weak self] in

            do {
                guard let myself :SMTPServer = self else {
                    return
                }
                // Create an IPV4 socket...
                try myself.listenSocket = Socket.create(family: .inet)

                guard let socket = myself.listenSocket else {
                    print("Unable to unwrap socket...")
                    return
                }

                try socket.listen(on: myself.port)

                print("Listening on port: \(socket.listeningPort)")

                repeat {
                    let newSocket = try socket.acceptClientConnection()

                    print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    print("Socket Signature: \(String(describing: newSocket.signature?.description))")

                    myself.addNewConnection(socket: newSocket)
                } while self?.continueRunning == true
                print("SMTP listening stopped")
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error...")
                    return
                }

                if self?.continueRunning == true {
                    print("Error reported:\n \(socketError.description)")
                }
            }
        }
//        dispatchMain()
    }

    private func addNewConnection(socket: Socket) {
        // Add the new socket to the list of connected sockets...
        socketLockQueue.sync { [unowned self, socket] in
            self.connectedSockets[socket.socketfd] = socket
        }

        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .default)

        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [weak self, socket] in
            var shouldKeepRunning = true
            var readData = Data(capacity: SMTPServer.bufferSize)

            do {
                // Write the welcome string...
                try socket.write(from: "Hello, type 'QUIT' to end session\n")

                repeat {
                    let bytesRead = try socket.read(into: &readData)

                    if bytesRead > 0 {
                        guard let response = String(data: readData, encoding: .utf8) else {

                            print("Error decoding response...")
                            readData.count = 0
                            break
                        }
                        print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
                        let reply = "Server response: \n\(response)\n"
                        try socket.write(from: reply)

                        if response.uppercased().hasPrefix(SMTPServer.quitCommand) && !response.hasPrefix(SMTPServer.quitCommand) {

                            try socket.write(from: "If you want to QUIT please type the name in all caps. 😃\n")
                        }

                        if response.hasPrefix(SMTPServer.quitCommand) || response.hasSuffix(SMTPServer.quitCommand) {

                            shouldKeepRunning = false
                        }
                    }

                    if bytesRead == 0 {

                        shouldKeepRunning = false
                        break
                    }

                    readData.count = 0

                } while shouldKeepRunning

                print("Socket: \(socket.remoteHostname):\(socket.remotePort) closed...")
                socket.close()

                self?.socketLockQueue.sync { [weak self, socket] in
//                    self.connectedSockets[socket.socketfd] = nil
                    _ = self?.connectedSockets.removeValue(forKey: socket.socketfd)
                }

            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    return
                }
                if self?.continueRunning == true {
                    print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                }
            }
        }
    }

    func shutdown() {
        print("\nSMTP shutdown in progress...")

        self.continueRunning = false

        // Close all open sockets...
        for socket in connectedSockets.values {

            self.socketLockQueue.sync { [weak self, socket] in
                self?.connectedSockets.removeValue(forKey: socket.socketfd)
                socket.close()
            }
        }
        self.listenSocket?.close()
        print("\nSMTP shutdown complete")
    }
}
