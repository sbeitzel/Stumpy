//
//  SMTPParseHandler.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/17/22.
//

import Foundation
import Logging
import NIO

final class SMTPParseHandler: ChannelInboundHandler {
    typealias InboundIn = SMTPSessionState
    typealias InboundOut = SMTPSessionState

    var logger: Logger

    init() {
        logger = Logger(label: "SMTPParseHandler")
        logger.logLevel = .trace
        logger[metadataKey: "origin"] = "[SMTP]"
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let currentState = unwrapInboundIn(data)

        // now, we look at the line that came in and turn it into an action
        switch currentState.smtpState {
        case .dataHeader:
            processDataHeaderMessage(currentState)
        case .dataBody:
            processDataBodyMessage(currentState)
        default:
            processMessage(currentState)
        }

        logger.trace("Input: \(currentState.inputLine)",
                     metadata: ["command": "\(String(describing: currentState.command?.action))"])

        // and pass it along for further handling
        context.fireChannelRead(wrapInboundOut(currentState))
    }

    // swiftlint:disable:next function_body_length
    private func processMessage(_ state: SMTPSessionState) {
        let allCaps = state.inputLine.uppercased()
        var params = state.inputLine
        if allCaps.hasPrefix("EHLO ") {
            if params.count > 5 {
                params.removeFirst(5)
            } else {
                params = ""
            }
            state.command = SMTPCommand(action: .ehlo, parameters: params)
        } else if allCaps.hasPrefix("HELO") {
            if params.count > 5 {
                params.removeFirst(5)
            } else {
                params = ""
            }
            state.command = SMTPCommand(action: .helo, parameters: params)
        } else if allCaps.hasPrefix("MAIL FROM:") {
            params.removeFirst(10)
            state.command = SMTPCommand(action: .mail, parameters: params)
        } else if allCaps.hasPrefix("RCPT TO:") {
            params.removeFirst(8)
            state.command = SMTPCommand(action: .rcpt, parameters: params)
        } else if allCaps.hasPrefix("DATA") {
            state.command = SMTPCommand(action: .data, parameters: "")
        } else if allCaps.hasPrefix("QUIT") {
            state.command = SMTPCommand(action: .quit, parameters: "")
        } else if allCaps.hasPrefix("RSET") {
            state.command = SMTPCommand(action: .rset, parameters: "")
        } else if allCaps.hasPrefix("NOOP") {
            state.command = SMTPCommand(action: .noop, parameters: "")
        } else if allCaps.hasPrefix("EXPN") {
            params.removeFirst(4)
            state.command = SMTPCommand(action: .expn, parameters: params)
        } else if allCaps.hasPrefix("VRFY") {
            params.removeFirst(4)
            state.command = SMTPCommand(action: .vrfy, parameters: params)
        } else if allCaps.hasPrefix("HELP") {
            state.command = SMTPCommand(action: .help, parameters: "")
        } else if allCaps.hasPrefix("LIST") { // not actually an SMTP command; allows inspecting the mail store
            params.removeFirst(4)
            state.command = SMTPCommand(action: .list, parameters: params)
        } else {
            state.command = SMTPCommand(action: .unknown, parameters: params)
        }
    }

    private func processDataHeaderMessage(_ state: SMTPSessionState) {
        if state.inputLine == "." {
            state.command = SMTPCommand(action: .dataEnd, parameters: "")
        } else if state.inputLine.isEmpty {
            state.command = SMTPCommand(action: .blankLine, parameters: "")
        } else {
            state.command = SMTPCommand(action: .unknown, parameters: state.inputLine)
        }
    }

    private func processDataBodyMessage(_ state: SMTPSessionState) {
        if state.inputLine == "." {
            state.command = SMTPCommand(action: .dataEnd, parameters: "")
        } else if state.inputLine.isEmpty {
            state.command = SMTPCommand(action: .unknown, parameters: "\n")
        } else {
            state.command = SMTPCommand(action: .unknown, parameters: state.inputLine)
        }
    }

}
