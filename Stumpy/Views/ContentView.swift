//
//  ContentView.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/21/20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataController: DataController

    @ObservedObject var servers: Servers

    @FetchRequest(entity: ServerSpec.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \ServerSpec.smtpPort, ascending: true)])
    var serverSpecs: FetchedResults<ServerSpec>

    @State var isLoaded: Bool = false

    init(_ theServers: Servers) {
        servers = theServers
    }

    func loadFromCoreData() {
        if !isLoaded {
            for spec in serverSpecs {
                servers.addTriad(from: spec)
            }
        }
        isLoaded = true
    }

    func clear() {
        servers.shutdown()
        servers.stores.removeAll()
        dataController.deleteAll()
        isLoaded = false
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: addStoreTriplet) {
                    Text("New Store")
                }
                Button(action: loadFromCoreData) {
                    Text("Load Saved")
                }
                    .disabled(isLoaded)
                Button(action: clear) {
                    Text("Delete Them All")
                }
                .disabled(servers.stores.isEmpty)
                Spacer()
            }
            .padding()
            ScrollView {
                ForEach(servers.stores) { triad in
                    HStack {
                        MailstoreControlView(store: triad.mailStore,
                                             smtpServer: triad.smtpServer,
                                             popServer: triad.popServer,
                                             serverSpec: triad.spec)
                        VStack {
                            Button(action: {
                                servers.remove(triad: triad)
                                dataController.delete(triad.spec)
                            }, label: {
                                Text("Delete")
                            })
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    func addStoreTriplet() {
        // first, we need a new record from the data controller
        let spec = dataController.createNewSpec()
        // now we can use that to create a new mail store & servers
        servers.addTriad(from: spec)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(Servers())
    }
}
