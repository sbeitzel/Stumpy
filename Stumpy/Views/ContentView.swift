//
//  ContentView.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/21/20.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var smtpServer: SMTPServer
    @ObservedObject var popServer: POPServer

    @State private var smtpPortString: String
    @State private var popPortString: String

    init(_ theServers: Servers) {
        smtpServer = theServers.smtpServer
        popServer = theServers.popServer
        _smtpPortString = State(wrappedValue: String(theServers.smtpServer.serverPort))
        _popPortString = State(wrappedValue: String(theServers.popServer.serverPort))
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: smtpServer.run) { Text("Start SMTP") }
                    .disabled(smtpServer.isRunning)
                TextField("SMTP Port:", text: $smtpPortString.onChange(setSMTPPort).validate(validateSMTPPort))
                Spacer()
                Button(action: smtpServer.shutdown) { Text("Stop SMTP") }
                    .disabled(!smtpServer.isRunning)
            }
            Text("Number of SMTP connections: \(smtpServer.numberConnected)")
                .padding()
            HStack {
                Button(action: popServer.run) { Text("Start POP3") }
                    .disabled(popServer.isRunning)
                TextField("POP3 Port:", text: $popPortString.onChange(setPOPPort).validate(validatePOPPort))
                Spacer()
                Button(action: popServer.shutdown) { Text("Stop POP3") }
                    .disabled(!popServer.isRunning)
            }
            Text("Number of POP conections: \(popServer.numberConnected)")
                .padding()
        }
    }

    private func setSMTPPort() {
        guard let portNum = Int(smtpPortString) else {
            return
        }
        smtpServer.serverPort = portNum
    }

    private func setPOPPort() {
        guard let portNum = Int(popPortString) else {
            return
        }
        popServer.serverPort = portNum
    }

    private func validateSMTPPort(_ value: String) -> Bool {
        return (Int(value) != nil && !smtpServer.isRunning)
    }

    private func validatePOPPort(_ value: String) -> Bool {
        return (Int(value) != nil && !popServer.isRunning)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(Servers())
    }
}
