//
//  MailstoreControlView.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/7/21.
//

import SwiftUI

struct MailstoreControlView: View {
    @ObservedObject var mailStore: FixedSizeMailStore
    @ObservedObject var smtpServer: SMTPServer
    @ObservedObject var popServer: POPServer

    @State private var smtpPortString: String
    @State private var popPortString: String

    init(store: FixedSizeMailStore, smtpServer: SMTPServer, popServer: POPServer) {
        mailStore = store
        self.smtpServer = smtpServer
        self.popServer = popServer
        _smtpPortString = State(wrappedValue: String(smtpServer.serverPort))
        _popPortString = State(wrappedValue: String(popServer.serverPort))
    }

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Button(action: buttonAction) { buttonLabel }
                        .frame(width: 55, height: 30)
                    Text("SMTP Port:")
                    TextField("SMTP Port", text: $smtpPortString.onChange(setSMTPPort).validate(validateSMTPPort))
                        .frame(minWidth: 60,
                               idealWidth: 80,
                               maxWidth: 80,
                               minHeight: 20,
                               idealHeight: 25,
                               maxHeight: 30,
                               alignment: .center)
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
                Text("\(smtpServer.numberConnected) SMTP connections")
                    .padding(EdgeInsets(top: 0,
                                        leading: 0,
                                        bottom: 5,
                                        trailing: 5))
                Text("\(popServer.numberConnected) POP3 connections")
                    .padding(EdgeInsets(top: 0,
                                        leading: 0,
                                        bottom: 5,
                                        trailing: 5))
                Text("\(mailStore.numberOfMessages) messages")
                    .padding(EdgeInsets(top: 0,
                                        leading: 0,
                                        bottom: 5,
                                        trailing: 5))
            }
            .padding()
            Spacer()
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

    private func buttonAction() {
        if smtpServer.isRunning {
            smtpServer.shutdown()
            popServer.shutdown()
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
        let triad = Servers.example()
        MailstoreControlView(store: triad.mailStore, smtpServer: triad.smtpServer, popServer: triad.popServer)
    }
}
