//
//  SMTPResponse.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/1/21.
//

import Foundation

/// The result of a client request being processed by the SMTP server.
struct SMTPResponse {
    /// Numeric response code  (see RFC-5321)[https://tools.ietf.org/html/rfc5321]
    let code: Int

    /// Human readable message describing the response
    let message: String

    /// The next state that the session will be in, upon client's receipt of this response
    let nextState: SMTPState
}
