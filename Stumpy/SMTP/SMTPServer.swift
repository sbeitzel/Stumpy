//  Created by Stephen Beitzel on 12/21/20.
//

import Foundation
import Socket
import Dispatch

/// The server part of the SMTP server that we implement.
class SMTPServer: ObservableObject {
    private static func log(_ message: String) -> Void {
        print("[SMTP] \(message)")
    }

    @Published var numberConnected: Int = 0
    @Published var isRunning = false

    private var port: Int
    var serverPort: Int {
        get {
            port
        }
        set(newPort) {
            if continueRunning == false {
                port = newPort
            } else {
                SMTPServer.log("Attempted to change port while server is running! Port not changed.")
            }
        }
    }

    private let mailStore: MailStore
    private var listenSocket: Socket? = nil
    private var continueRunningValue = false
    private var connectedSockets = [Int32: Socket]()
    private let socketLockQueue = DispatchQueue(label: "com.qbcps.Stumpy.smtpSocketQ")
    private var continueRunning: Bool {
        set(newValue) {
            socketLockQueue.sync {
                SMTPServer.log("Setting SMTP continueRunning to \(newValue)")
                continueRunningValue = newValue
                DispatchQueue.main.async {
                    self.isRunning = newValue
                }
            }
        }
        get {
            return socketLockQueue.sync {
                self.continueRunningValue
            }
        }
    }

    init(port: Int, store: MailStore = FixedSizeMailStore(size: 10)) {
        self.port = port
        mailStore = store
    }

    deinit {
        // Close all open sockets...
        for socket in connectedSockets.values {
            removeConnection(socket)
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
                    SMTPServer.log("Unable to unwrap socket...")
                    return
                }

                try socket.listen(on: myself.port)

                SMTPServer.log("Listening on port: \(socket.listeningPort)")

                repeat {
                    let newSocket = try socket.acceptClientConnection()

                    SMTPServer.log("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    SMTPServer.log("Socket Signature: \(String(describing: newSocket.signature?.description))")

                    myself.addNewConnection(socket: newSocket)
                } while self?.continueRunning == true
                SMTPServer.log("SMTP listening stopped")
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    SMTPServer.log("Unexpected error...")
                    return
                }

                if self?.continueRunning == true {
                    SMTPServer.log("Error reported:\n \(socketError.description)")
                }
            }
        }
        //        dispatchMain()
    }

    private func removeConnection(_ socket: Socket) {
        SMTPServer.log("Socket: \(socket.remoteHostname):\(socket.remotePort) closing...")
        let socketKey = socket.socketfd
        socket.close()
        socketLockQueue.sync { [unowned self] in
            SMTPServer.log("Removing socket for key \(socketKey)")
            connectedSockets.removeValue(forKey: socketKey)
            DispatchQueue.main.async {
                objectWillChange.send()
                numberConnected -= 1
                SMTPServer.log("Connection count decremented to \(numberConnected)")
            }
        }
    }

    private func addNewConnection(socket: Socket) {
        // Add the new socket to the list of connected sockets...
        socketLockQueue.sync { [unowned self, socket] in
            SMTPServer.log("New connection added to list")
            connectedSockets[socket.socketfd] = socket
            DispatchQueue.main.async {
                objectWillChange.send()
                numberConnected += 1
                SMTPServer.log("Connection count incremented to \(numberConnected)")
            }
        }

        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .default)

        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [weak self, socket] in
            guard let store = self?.mailStore else {
                return
            }
            let clientSession = SMTPSession(socket: socket, mailStore: store)
            clientSession.run()
            self?.removeConnection(socket)
        }
    }

    func shutdown() {
        SMTPServer.log("\nSMTP shutdown in progress...")

        continueRunning = false

        // Close all open sockets...
        for socket in connectedSockets.values {
            removeConnection(socket)
        }
        listenSocket?.close()
        SMTPServer.log("\nSMTP shutdown complete")
    }
}
