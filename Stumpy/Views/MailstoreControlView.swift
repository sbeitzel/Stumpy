//
//  MailstoreControlView.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/7/21.
//

import StumpyNIO
import SwiftUI

struct MailstoreControlView: View {
    @ObservedObject var mailStore: FixedSizeMailStore
    @ObservedObject var smtpServer: NSMTPServer
    @ObservedObject var smtpStats: ServerStats
    @ObservedObject var popServer: NPOPServer
    @ObservedObject var popStats: ServerStats
    @ObservedObject var serverSpec: ServerSpec

    @State private var smtpPortString: String
    @State private var popPortString: String
    @State private var messageCountString: String
    @State private var smtpConnected = 0
    @State private var popConnected = 0
    @State private var allowMultipleMail = true

    init(store: FixedSizeMailStore,
         smtpServer: NSMTPServer,
         popServer: NPOPServer,
         serverSpec: ServerSpec) {
        mailStore = store
        self.smtpServer = smtpServer
        self.smtpStats = smtpServer.serverStats
        self.popServer = popServer
        self.popStats = popServer.serverStats
        self.allowMultipleMail = serverSpec.allowMultiMail
        _smtpPortString = State(wrappedValue: String(smtpServer.serverPort))
        _popPortString = State(wrappedValue: String(popServer.serverPort))
        _messageCountString = State(wrappedValue: "0")
        self.serverSpec = serverSpec
    }

    var body: some View {
        HStack {
            VStack {
                HStack(alignment: .top) {
                    Button(action: buttonAction) { buttonLabel }
                    .frame(width: 55, height: 30)
                    VStack {
                        Toggle(isOn: $allowMultipleMail.maybeChange({ newValue in
                            return smtpServer.allowMultipleEmails(newValue)
                        }).onChange {
                            setAllowMultipleMail()
                        }) {
                            Text("Allow multiple MAIL transactions per session")
                        }.disabled(smtpServer.isRunning)
                        HStack {
                            Text("SMTP Port:")
                            TextField("SMTP Port",
                                      text: $smtpPortString.onChange(setSMTPPort).validate(validateSMTPPort))
                                .frame(minWidth: 60,
                                       idealWidth: 80,
                                       maxWidth: 80,
                                       minHeight: 20,
                                       idealHeight: 25,
                                       maxHeight: 30,
                                       alignment: .center)
                        }
                    }
                }
                HStack {
                    Circle()
                        .fill(Color(smtpServer.isRunning ? .green : .red))
                        .frame(width: 55,
                               height: 30)
                    Text("POP3 Port:")
                    TextField("POP3 Port", text: $popPortString.onChange(setPOPPort).validate(validatePOPPort))
                        .frame(minWidth: 60,
                               idealWidth: 80,
                               maxWidth: 80,
                               minHeight: 20,
                               idealHeight: 25,
                               maxHeight: 30,
                               alignment: .center)
                }
            }
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 0))
            VStack(alignment: .leading) {
                Text("\(smtpConnected) SMTP connections")
                    .onReceive(smtpStats.objectWillChange) {
                        Task {
                            smtpConnected = smtpStats.connections
                        }
                    }
                    .padding(EdgeInsets(top: 0,
                                        leading: 0,
                                        bottom: 5,
                                        trailing: 5))
                Text("\(popConnected) POP3 connections")
                    .onReceive(popStats.objectWillChange) {
                        Task {
                            popConnected = popStats.connections
                        }
                    }
                    .padding(EdgeInsets(top: 0,
                                        leading: 0,
                                        bottom: 5,
                                        trailing: 5))
                Text("\(messageCountString) messages")
                    .onReceive(mailStore.objectWillChange) {
                        Task {
                            let messageCount = await mailStore.messageCount()
                            messageCountString = "\(messageCount)"
                        }
                    }
                    .padding(EdgeInsets(top: 0,
                                        leading: 0,
                                        bottom: 5,
                                        trailing: 5))
            }
            .padding()
            Spacer()
        }
        .border(Color.gray, width: 1)
        .padding()
    }

    private func setAllowMultipleMail() {
        serverSpec.allowMultiMail = allowMultipleMail
    }

    private func setSMTPPort() {
        guard let portNum = Int(smtpPortString) else {
            return
        }
        smtpServer.serverPort = portNum
        serverSpec.smtpPort = Int16(portNum)
    }

    private func setPOPPort() {
        guard let portNum = Int(popPortString) else {
            return
        }
        popServer.serverPort = portNum
        serverSpec.popPort = Int16(portNum)
    }

    private func validateSMTPPort(_ value: String) -> Bool {
        guard let port: Int = Int(value) else {
            // not a number
            return false
        }
        guard port <= Int16.max else {
            // number is too big
            return false
        }
        // only allowed to change ports when the server is stopped
        return !smtpServer.isRunning
    }

    private func validatePOPPort(_ value: String) -> Bool {
        guard let port: Int = Int(value) else {
            // not a number
            return false
        }
        guard port <= Int16.max else {
            // number is too big
            return false
        }
        // only allowed to change ports when the server is stopped
        return !popServer.isRunning
    }

    private func buttonAction() {
        if smtpServer.isRunning {
            smtpServer.stop()
            popServer.stop()
        } else {
            smtpServer.run()
            popServer.run()
        }
    }

    var buttonLabel: Text {
        if smtpServer.isRunning {
            return Text("Stop")
        }
        return Text("Start")
    }
}

struct MailstoreControlView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = DataController.preview
        let triad = Servers.example(controller)
        MailstoreControlView(store: triad.mailStore,
                             smtpServer: triad.smtpServer,
                             popServer: triad.popServer,
                             serverSpec: triad.spec)
    }
}
