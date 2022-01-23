//  Created by Stephen Beitzel on 12/21/20.
//

import Foundation
import Logging
import NIO

class NSMTPServer: ObservableObject {
    private var logger: Logger
    private let mailStore: MailStore
    private var port: Int
    var serverPort: Int {
        get {
            port
        }
        set {
            if isRunning == false {
                port = newValue
            } else {
                logger.warning("Attempted to change port while server is running! Port not changed.")
            }
        }
    }
    private let bootstrap: ServerBootstrap
    private var serverChannel: Channel?

    @Published var isRunning: Bool = false
    let serverStats: ServerStats

    init(group: EventLoopGroup, port: Int, store: MailStore = FixedSizeMailStore(size: 10)) {
        logger = Logger(label: "SMTPServer")
        logger[metadataKey: "origin"] = "[SMTP]"
        let stats = ServerStats()
        serverStats = stats
        self.port = port
        self.mailStore = store
        self.bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandlers([
                    BackPressureHandler(),
                    DebugLoggingHandler(),
                    SMTPSessionHandler(with: store,
                                       increment: stats.increaseConnectionCount,
                                       decrement: stats.decreaseConnectionCount),
                    SMTPActionHandler()
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
                    serverChannel = try bootstrap.bind(host: "localhost", port: port).wait()
                    logger.info("Server started, listening on address: \(serverChannel!.localAddress!.description)")
                    try serverChannel!.closeFuture.wait()
                    logger.info("Server stopped.")
                    DispatchQueue.main.async {
                        self.isRunning = false
                    }
                } catch {
                    logger.critical("Error running SMTP server: \(error.localizedDescription)")
                }
            }
        }
    }

    func stop() {
        if let channel = serverChannel {
            logger.info("SMTP server shutting down")
            _ = channel.close(mode: CloseMode.all)
            self.serverChannel = nil
        }
    }
}
