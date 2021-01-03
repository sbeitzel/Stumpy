//  Created by Stephen Beitzel on 12/21/20.
//

import Foundation
import Socket
import Dispatch

/// The server part of the POP3 server that we implement.
class POPServer: ObservableObject {

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
                print("Attempted to change port while server is running! Port not changed.")
            }
        }
    }

    private let mailStore: MailStore
    private var listenSocket: Socket? = nil
    private var continueRunningValue = false
    private var connectedSockets = [Int32: Socket]()
    private let socketLockQueue = DispatchQueue(label: "com.qbcps.Stumpy.popSocketQ")
    private var continueRunning: Bool {
        set(newValue) {
            socketLockQueue.sync {
                print("Setting POP continueRunning to \(newValue)")
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
                guard let myself :POPServer = self else {
                    return
                }
                // Create an IPV4 socket...
                try myself.listenSocket = Socket.create(family: .inet)

                guard let socket = myself.listenSocket else {
                    print("Unable to unwrap socket...")
                    return
                }

                try socket.listen(on: myself.port)

                print("Stumpy POP3 listening on port: \(socket.listeningPort)")

                repeat {
                    let newSocket = try socket.acceptClientConnection()

                    print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    print("Socket Signature: \(String(describing: newSocket.signature?.description))")

                    myself.addNewConnection(socket: newSocket)
                } while self?.continueRunning == true
                print("POP listening stopped")
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

    private func removeConnection(_ socket: Socket) {
        print("Socket: \(socket.remoteHostname):\(socket.remotePort) closing...")
        let socketKey = socket.socketfd
        socket.close()
        socketLockQueue.sync { [unowned self] in
            print("Removing socket for key \(socketKey)")
            connectedSockets.removeValue(forKey: socketKey)
            DispatchQueue.main.async {
                objectWillChange.send()
                numberConnected -= 1
                print("Connection count decremented to \(numberConnected)")
            }
        }
    }

    private func addNewConnection(socket: Socket) {
        // Add the new socket to the list of connected sockets...
        socketLockQueue.sync { [unowned self, socket] in
            print("New connection added to list")
            connectedSockets[socket.socketfd] = socket
            DispatchQueue.main.async {
                objectWillChange.send()
                numberConnected += 1
                print("Connection count incremented to \(numberConnected)")
            }
        }

        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .default)

        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [weak self, socket] in
            guard let store = self?.mailStore else {
                return
            }
            let clientSession = POPSession(socket: socket, mailStore: store)
            clientSession.run()
            self?.removeConnection(socket)
        }
    }

    func shutdown() {
        print("\nPOP3 shutdown in progress...")

        continueRunning = false

        // Close all open sockets...
        for socket in connectedSockets.values {
            removeConnection(socket)
        }
        listenSocket?.close()
        print("\nPOP3 shutdown complete")
    }
}
