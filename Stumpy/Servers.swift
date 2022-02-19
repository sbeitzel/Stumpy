//
//  Servers.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/22/20.
//

import SwiftUI
import CoreData
import NIO
import StumpyNIO

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

        // before adding the triad, check to see if we've already got this one
        if stores.filter({ $0.id == spec.idString }).isEmpty {
            objectWillChange.send()
            let store = FixedSizeMailStore(size: Int(spec.mailSlots), id: spec.idString)
            stores.append(ServiceTriad(smtpServer: NSMTPServer(group: dataController.smtpGroup,
                                                               port: Int(spec.smtpPort),
                                                               store: store,
                                                               acceptMultipleMails: spec.allowMultiMail),
                                       popServer: NPOPServer(group: dataController.popGroup,
                                                             port: Int(spec.popPort),
                                                             store: store),
                                       mailStore: store,
                                       spec: spec)
            )
        }
    }

    func remove(triad: ServiceTriad) {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
            triad.smtpServer.stop()
            triad.popServer.stop()
            self?.stores.removeAll(where: { $0.id == triad.id })
        }
    }

    func shutdown() {
        print("\nAll servers shutting down")
        for triad in stores {
            triad.smtpServer.stop()
            triad.popServer.stop()
        }
        dataController?.save()
    }

    static public func example(_ controller: DataController) -> ServiceTriad {
        let serverSpec = controller.createNewSpec()
        let store = FixedSizeMailStore(size: Int(serverSpec.mailSlots), id: serverSpec.idString)
        let smtpServer = NSMTPServer(group: controller.smtpGroup, port: Int(serverSpec.smtpPort), store: store)
        let popServer = NPOPServer(group: controller.popGroup, port: Int(serverSpec.popPort), store: store)
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
    let popServer: NPOPServer
    let mailStore: FixedSizeMailStore
    let spec: ServerSpec
}
