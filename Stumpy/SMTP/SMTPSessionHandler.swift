//
//  SMTPSessionHandler.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/16/22.
//

import Foundation
import NIO

final class SMTPSessionHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = SMTPSessionState

    let sessionState: SMTPSessionState
    let incrementCallback: () -> Void
    let decrementCallback: () -> Void

    init(with store: MailStore,
         increment: @escaping () -> Void,
         decrement: @escaping () -> Void) {
        sessionState = SMTPSessionState(with: store)
        incrementCallback = increment
        decrementCallback = decrement
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // this is how you turn a buffer into a string
        // first, get the buffer -- unwrapInboundIn does typecasting
        let inBuffer = unwrapInboundIn(data)
        let inString = inBuffer.getString(at: 0, length: inBuffer.readableBytes) ?? ""

        sessionState.inputLine = inString

        context.fireChannelRead(wrapInboundOut(sessionState))
    }

    func channelActive(context: ChannelHandlerContext) {
        let banner = "220 Stumpy SMTP service ready\r\n"
        var outBuff = context.channel.allocator.buffer(capacity: banner.count)
        outBuff.writeString(banner)

        context.writeAndFlush(NIOAny(outBuff), promise: nil)
        sessionState.smtpState = .greet
        Task {
            self.incrementCallback()
        }
        context.fireChannelActive()
    }

    func channelInactive(context: ChannelHandlerContext) {
        Task {
            self.decrementCallback()
        }
        context.fireChannelInactive()
    }
}
