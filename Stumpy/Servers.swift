//
//  Servers.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/22/20.
//

import SwiftUI
import CoreData
import NIO

class Servers: ObservableObject {
    @Published var stores: [ServiceTriad]

    var dataController: DataController?

    init() {
        stores = [ServiceTriad]()
    }

    func addTriad(from spec: ServerSpec) {
        guard let dataController = dataController else {
            return
        }

        objectWillChange.send()
        let store = FixedSizeMailStore(size: Int(spec.mailSlots), id: spec.idString)
        stores.append(ServiceTriad(smtpServer: NSMTPServer(group: dataController.smtpGroup,
                                                           port: Int(spec.smtpPort),
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
            triad.smtpServer.stop()
            triad.popServer.shutdown()
            self?.stores.removeAll(where: { $0.id == triad.id })
        }
    }

    func shutdown() {
        print("\nAll servers shutting down")
        for triad in stores {
            triad.smtpServer.stop()
            triad.popServer.shutdown()
        }
        dataController?.save()
    }

    static public func example(_ controller: DataController) -> ServiceTriad {
        let serverSpec = controller.createNewSpec()
        let store = FixedSizeMailStore(size: Int(serverSpec.mailSlots), id: serverSpec.idString)
        let smtpServer = NSMTPServer(group: controller.smtpGroup, port: Int(serverSpec.smtpPort), store: store)
        let popServer = POPServer(port: Int(serverSpec.popPort), store: store)
        Task {
            await store.add(message: MemoryMessage.example())
        }
        return ServiceTriad(smtpServer: smtpServer, popServer: popServer, mailStore: store, spec: serverSpec)
    }
}

struct ServiceTriad: Identifiable {
    public var id: String {
        mailStore.id
    }

    let smtpServer: NSMTPServer
    let popServer: POPServer
    let mailStore: FixedSizeMailStore
    let spec: ServerSpec
}
