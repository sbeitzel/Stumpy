//
//  ContentView.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/21/20.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var servers: Servers

    init(_ theServers: Servers) {
        servers = theServers
    }

    var body: some View {
        ForEach(servers.stores) { triad in
            MailstoreControlView(store: triad.mailStore,
                                 smtpServer: triad.smtpServer,
                                 popServer: triad.popServer)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(Servers())
    }
}
