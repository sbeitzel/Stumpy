//  Created by Stephen Beitzel on 12/21/20.
//

import Foundation
import Logging
import NIO

/// The server part of the POP3 server that we implement.
class NPOPServer: ObservableObject {
    private var logger: Logger
    private let mailStore: MailStore
    private let bootstrap: ServerBootstrap
    private var serverChannel: Channel?

    @Published var isRunning = false
    let serverStats: ServerStats

    private var port: Int
    var serverPort: Int {
        get {
            port
        }
        set(newPort) {
            if isRunning == false {
                port = newPort
            } else {
                logger.info("Attempted to change port while server is running! Port not changed.")
            }
        }
    }

    init(group: EventLoopGroup, port: Int, store: MailStore = FixedSizeMailStore(size: 10)) {
        logger = Logger(label: "POP3Server")
        logger[metadataKey: "origin"] = "[POP3]"
        let stats = ServerStats()
        self.serverStats = stats
        self.port = port
        self.mailStore = store
        self.bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandlers([
                    BackPressureHandler(),
                    DebugLoggingHandler(),
                    POPSessionHandler(with: store,
                                      increment: stats.increaseConnectionCount,
                                      decrement: stats.decreaseConnectionCount,
                                      hostName: "stumpy.local"), // hostname is for the APOP header
                    POPParseHandler(),
                    POPActionHandler()
                ])
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }

    func run() {
        if !isRunning {
            objectWillChange.send()
            isRunning = true
            Task {
                do {
                    serverChannel = try bootstrap.bind(host: "::1", port: port).wait()
                    logger.info("Server started, listening on address: \(serverChannel!.localAddress!.description)")
                    try serverChannel!.closeFuture.wait()
                    logger.info("Server stopped.")
                    DispatchQueue.main.async {
                        self.isRunning = false
                    }
                } catch {
                    logger.critical("Error running POP3 server: \(error.localizedDescription)")
                }
            }
        }
    }

    func stop() {
        if let channel = serverChannel {
            logger.info("POP3 server shutting down")
            _ = channel.close(mode: CloseMode.all)
            self.serverChannel = nil
        }
    }
}
