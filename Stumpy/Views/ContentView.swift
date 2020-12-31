//
//  ContentView.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/21/20.
//

import SwiftUI

struct ContentView: View {
    let servers: Servers

    @State private var mailRunning: Bool

    init(_ theServers: Servers) {
        servers = theServers
        _mailRunning = State(wrappedValue: theServers.smtpServer.continueRunning)
    }

    var body: some View {
        VStack {
            Toggle("SMTP Running", isOn: $mailRunning.onChange(update))
        }
    }

    func update() {
        servers.objectWillChange.send()
        if (mailRunning == true) {
            servers.smtpServer.run()
        } else {
            servers.smtpServer.shutdown()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(Servers())
    }
}
