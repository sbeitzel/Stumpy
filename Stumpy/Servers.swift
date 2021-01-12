//
//  Servers.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/22/20.
//

import SwiftUI
import CoreData

class Servers: ObservableObject {
    @Published var stores: [ServiceTriad]

    var dataController: DataController?

    init() {
        stores = [ServiceTriad]()
    }

    func addTriad(from spec: ServerSpec) {
        objectWillChange.send()
        let store = FixedSizeMailStore(size: Int(spec.mailSlots), id: spec.idString)
        stores.append(ServiceTriad(smtpServer: SMTPServer(port: Int(spec.smtpPort),
                                                          store: store),
                                   popServer: POPServer(port: Int(spec.popPort),
                                                        store: store),
                                   mailStore: store,
                                   spec: spec)
        )
    }

    func remove(triad: ServiceTriad) {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
            triad.smtpServer.shutdown()
            triad.popServer.shutdown()
            self?.stores.removeAll(where: { $0.id == triad.id })
        }
    }

    func shutdown() {
        print("\nAll servers shutting down")
        for triad in stores {
            triad.smtpServer.shutdown()
            triad.popServer.shutdown()
        }
        dataController?.save()
    }

    static public func example(_ controller: DataController) -> ServiceTriad {
        let serverSpec = controller.createNewSpec()
        let store = FixedSizeMailStore(size: Int(serverSpec.mailSlots), id: serverSpec.idString)
        let smtpServer = SMTPServer(port: Int(serverSpec.smtpPort), store: store)
        let popServer = POPServer(port: Int(serverSpec.popPort), store: store)
        store.add(message: MemoryMessage.example())
        return ServiceTriad(smtpServer: smtpServer, popServer: popServer, mailStore: store, spec: serverSpec)
    }
}

struct ServiceTriad: Identifiable {
    public var id: String {
        mailStore.id
    }

    let smtpServer: SMTPServer
    let popServer: POPServer
    let mailStore: FixedSizeMailStore
    let spec: ServerSpec
}
