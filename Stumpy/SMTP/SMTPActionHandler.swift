//
//  SMTPActionHandler.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/17/22.
//

import Foundation
import Logging
import NIO

// This is the big state machine, where we look at the current state,
// what the incoming action is, and how we should mutate the state
// and what message we should send back to the client.

final class SMTPActionHandler: ChannelInboundHandler {
    typealias InboundIn = SMTPSessionState
    typealias InboundOut = ByteBuffer

    var logger: Logger

    init() {
        logger = Logger(label: "SMTPActionHandler")
        logger.logLevel = .info
        logger[metadataKey: "origin"] = "[SMTP]"
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let currentState = unwrapInboundIn(data)

        // Figuring out what comes next might take some time. We're going
        // to go async and do that work, and the rest of the pipeline
        // will just wait for us.
        Task {
            let response = await computeResponse(currentState)
            // now, we *might* want to mutate the current message
            store(currentState)
            // and we *might* want to put the message into the mail store
            if currentState.smtpState == .quit {
                if hasMessageIDHeader(currentState.workingMessage) {
                    let saveMessage = currentState.workingMessage
                    currentState.workingMessage = MemoryMessage()
                    Task {
                        await currentState.mailstore.add(message: saveMessage)
                    }
                } else {
                    logger.info("No message-id header, so not saving the working message")
                }
            }

            // and finally, we send a response message back to the client
            var respMessage = ""
            if response.code > 0 {
                // we send back the numeric code -- unless we're just accepting
                // data for a mail message
                respMessage.append("\(response.code) \(response.message)")
            }
            context.eventLoop.execute {
                if !(respMessage.hasSuffix("\r\n") || respMessage.hasSuffix("\n") || respMessage.isEmpty) {
                    respMessage.append("\n")
                }
                var outBuffer = context.channel.allocator.buffer(capacity: respMessage.count)
                outBuffer.writeString(respMessage)
                context.writeAndFlush(self.wrapInboundOut(outBuffer), promise: nil)
                if currentState.smtpState == .quit {
                    _ = context.close()
                }
            }
        }
    }

    /// The RFC states that there should be a message-id header, but it neglects to
    /// specify the capitalization. Apple Mail creates "Message-Id" while Thunderbird
    /// creates "Message-ID". So this method just uppercases all the headers and
    /// returns true if any of them are "MESSAGE-ID", since apparently the Internet
    /// doesn't care.
    /// - Returns: true if there's a message ID
    private func hasMessageIDHeader(_ message: MailMessage) -> Bool {
        for header in message.headers.keys {
            if header.uppercased() == "MESSAGE-ID" {
                logger.trace("Found a message ID header: \(header)")
                return true
            }
        }
        return false
    }

    func store(_ state: SMTPSessionState) {
        if let input = state.command?.parameters {
            if !input.isEmpty {
                logger.trace("storing input to message", metadata: ["input": "\(input)"])
                if state.smtpState == .dataHeader {
                    logger.trace("storing a header")
                    // this is either a header ('X-Sender: foo@mx.place') or it's
                    // a header continuation (that is, it's a second value that we should add
                    // to the last header we processed)
                    let isNewHeader = input.contains(":")
                    if isNewHeader {
                        logger.trace("new header")
                        let start = input.firstIndex(of: ":")
                        let header = String(input[input.startIndex ..< start!])
                        var value: String
                        value = String(input[start! ..< input.endIndex])
                        value.removeFirst()
                        state.workingMessage.set(value: value, for: header)
                        state.lastHeader = header
                    } else {
                        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
                        state.workingMessage.appendHeader(value: value, to: state.lastHeader)
                    }
                } else if state.smtpState == .dataBody {
                    logger.trace("appending line to message")
                    state.workingMessage.append(line: input)
                } else {
                    logger.trace("SMTP state is: \(state.smtpState); no input stored to message")
                }
            } else {
                logger.trace("input line is empty, not writing to message")
            }
        } else {
            // we don't have a command at all
            logger.warning("No command to act on!", metadata: ["input": "\(state.inputLine)"])
        }
    }

    // swiftlint:disable:next function_body_length
    func computeResponse(_ state: SMTPSessionState) async -> SMTPResponse {
        if let command = state.command {
            switch command.action {
            case .blankLine:
                if state.smtpState == .dataHeader {
                    // blank line separates headers from body
                    state.smtpState = .dataBody
                    return SMTPResponse(code: -1, message: "")
                } else if state.smtpState == .dataBody {
                    return SMTPResponse(code: -1, message: "")
                } else {
                    return .badSequence
                }

            case .data:
                if state.smtpState == .rcpt {
                    state.smtpState = .dataHeader
                    return SMTPResponse(code: 354,
                                        message: "Start mail input; end with <CRLF>.<CRLF>")
                } else {
                    return .badSequence
                }

            case .dataEnd:
                if state.smtpState == .dataBody || state.smtpState == .dataHeader {
                    state.smtpState = .mail
                    return SMTPResponse(code: 250,
                                        message: "OK")
                } else {
                    return .badSequence
                }

            case .helo:
                if state.smtpState == .greet {
                    state.smtpState = .mail
                    return SMTPResponse(code: 250,
                                        message: "Hello \(command.parameters)")
                } else {
                    return .badSequence
                }

            case .ehlo:
                if state.smtpState == .greet {
                    state.smtpState = .mail
                    return SMTPResponse(code: 250,
                                        message: "local.stumpy Hello \(command.parameters)\r\n250 OK")
                } else {
                    return .badSequence
                }

            case .expn:
                return SMTPResponse(code: 252,
                                    message: "Not supported")

            case .help:
                return SMTPResponse(code: 211,
                                    message: "No help available")

            case .list: // not an SMTP command, this is to allow for inspection of the mailstore
                var messageIndex: Int?
                if !command.parameters.isEmpty {
                    messageIndex = Int(command.parameters.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                var result = ""
                let messages = await state.mailstore.list()
                // swiftlint:disable:next identifier_name
                if let mi = messageIndex {
                    if mi > -1 && mi < messages.count-1 {
                        result.append("\n-------------------------------------------\n")
                        result.append(messages[mi].toString())
                    }
                }
                result.append("There are \(messages.count) messages")
                return SMTPResponse(code: 250,
                                    message: result)

            case .mail:
                if state.smtpState == .mail || state.smtpState == .quit {
                    state.smtpState = .rcpt
                    return SMTPResponse(code: 250, message: "OK")
                } else {
                    return .badSequence
                }

            case .noop:
                return SMTPResponse(code: 250, message: "OK")

            case .quit:
                state.smtpState = .quit
                return SMTPResponse(code: 221,
                                    message: "Stumpy SMTP service closing transmission channel")

            case .rcpt:
                if state.smtpState == .rcpt {
                    return SMTPResponse(code: 250, message: "OK")
                } else {
                    return .badSequence
                }

            case .rset:
                state.workingMessage = MemoryMessage()
                state.smtpState = .greet
                return SMTPResponse(code: 250, message: "OK")

            case .vrfy:
                return SMTPResponse(code: 252, message: "Not Supported")

            case .unknown:
                if state.smtpState == .dataHeader || state.smtpState == .dataBody {
                    return SMTPResponse(code: -1, message: "")
                } else {
                    return SMTPResponse(code: 500, message: "Command not recognized")
                }
            }
        } else {
            logger.critical("There's no command!!!")
            return .badSequence
        }
    }
}
