//
//  ContentView.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/21/20.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var smtpServer: SMTPServer

    init(_ theServers: Servers) {
        smtpServer = theServers.smtpServer
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    smtpServer.run()
                }) {
                    Text("Start SMTP")
                }
                    .disabled(smtpServer.isRunning)
                Spacer()
                Button(action: {
                    smtpServer.shutdown()
                }) {
                    Text("Stop SMTP")
                }
                .disabled(!smtpServer.isRunning)
            }
            Text("Number of connections: \(smtpServer.numberConnected)")
                .padding()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(Servers())
    }
}
