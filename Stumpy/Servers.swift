//
//  Servers.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/22/20.
//

import Foundation

class Servers: ObservableObject {
    @Published var stores: [ServiceTriad]
    let dataController: DataController = DataController()

    init() {
        stores = [ServiceTriad]()
        let store = FixedSizeMailStore(size: 100)
        stores.append(ServiceTriad(smtpServer: SMTPServer(port: 1081, store: store),
                                   popServer: POPServer(port: 9191, store: store),
                                   mailStore: store))
        let store2 = FixedSizeMailStore(size: 100)
        stores.append(ServiceTriad(smtpServer: SMTPServer(port: 1082, store: store2),
                                   popServer: POPServer(port: 9192, store: store2),
                                   mailStore: store2))
    }

    func shutdown() {
        dataController.save()
        print("\nAll servers shutting down")
        for triad in stores {
            triad.smtpServer.shutdown()
            triad.popServer.shutdown()
        }
    }

    static public func example() -> ServiceTriad {
        let store = FixedSizeMailStore(size: 10)
        let smtpServer = SMTPServer(port: 1082, store: store)
        let popServer = POPServer(port: 9191, store: store)
        store.add(message: MemoryMessage.example())
        return ServiceTriad(smtpServer: smtpServer, popServer: popServer, mailStore: store)
    }
}

struct ServiceTriad: Identifiable {
    public var id: String {
        mailStore.id
    }

    let smtpServer: SMTPServer
    let popServer: POPServer
    let mailStore: FixedSizeMailStore
}
