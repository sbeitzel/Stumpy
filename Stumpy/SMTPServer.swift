//  Created by Stephen Beitzel on 12/21/20.
//

import Foundation
import Socket
import Dispatch

class SMTPServer: ObservableObject {

    static let quitCommand: String = "QUIT"
    static let shutdownCommand: String = "SHUTDOWN"
    static let bufferSize = 4096

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
    var listenSocket: Socket? = nil
    var continueRunningValue = false
    var connectedSockets = [Int32: Socket]()
    let socketLockQueue = DispatchQueue(label: "com.kitura.serverSwift.socketLockQueue")
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

        queue.async { [unowned self] in

            do {
                // Create an IPV4 socket...
                try self.listenSocket = Socket.create(family: .inet)

                guard let socket = self.listenSocket else {
                    print("Unable to unwrap socket...")
                    return
                }

                try socket.listen(on: self.port)

                print("Listening on port: \(socket.listeningPort)")

                repeat {
                    let newSocket = try socket.acceptClientConnection()

                    print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    print("Socket Signature: \(String(describing: newSocket.signature?.description))")

                    self.addNewConnection(socket: newSocket)
                } while self.continueRunning
                print("SMTP listening stopped")
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error...")
                    return
                }

                if self.continueRunning {
                    print("Error reported:\n \(socketError.description)")
                }
            }
        }
//        dispatchMain()
    }

    func addNewConnection(socket: Socket) {
        // Add the new socket to the list of connected sockets...
        socketLockQueue.sync { [unowned self, socket] in
            self.connectedSockets[socket.socketfd] = socket
        }

        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .default)

        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [unowned self, socket] in
            var shouldKeepRunning = true
            var readData = Data(capacity: SMTPServer.bufferSize)

            do {
                // Write the welcome string...
                try socket.write(from: "Hello, type 'QUIT' to end session\nor 'SHUTDOWN' to stop server.\n")

                repeat {
                    let bytesRead = try socket.read(into: &readData)

                    if bytesRead > 0 {
                        guard let response = String(data: readData, encoding: .utf8) else {

                            print("Error decoding response...")
                            readData.count = 0
                            break
                        }
                        if response.hasPrefix(SMTPServer.shutdownCommand) {

                            print("Shutdown requested by connection at \(socket.remoteHostname):\(socket.remotePort)")

                            // Shut things down...
                            self.shutdownServer()

                            return
                        }
                        print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
                        let reply = "Server response: \n\(response)\n"
                        try socket.write(from: reply)

                        if (response.uppercased().hasPrefix(SMTPServer.quitCommand) || response.uppercased().hasPrefix(SMTPServer.shutdownCommand)) &&
                            (!response.hasPrefix(SMTPServer.quitCommand) && !response.hasPrefix(SMTPServer.shutdownCommand)) {

                            try socket.write(from: "If you want to QUIT or SHUTDOWN, please type the name in all caps. 😃\n")
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

                self.socketLockQueue.sync { [unowned self, socket] in
//                    self.connectedSockets[socket.socketfd] = nil
                    _ = self.connectedSockets.removeValue(forKey: socket.socketfd)
                }

            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    return
                }
                if self.continueRunning {
                    print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                }
            }
        }
    }

    func shutdownServer() {
        print("\nSMTP shutdown in progress...")

        self.continueRunning = false

        // Close all open sockets...
        for socket in connectedSockets.values {

            self.socketLockQueue.sync { [unowned self, socket] in
                self.connectedSockets.removeValue(forKey: socket.socketfd)
                socket.close()
            }
        }
        print("\nSMTP shutdown complete")
    }
}
