//
//  SMTPRequest.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/1/21.
//

import Foundation

struct SMTPRequest {
    var action: SMTPAction
    var state: SMTPState
    var params: String

    static func initialRequest() -> SMTPRequest {
        SMTPRequest(action: ConnectAction(), state: SMTPState.CONNECT, params: "")
    }

    func execute(with message: MailMessage, on store: MailStore) -> SMTPResponse {
        action.getResponse(state: state, store: store, message: message)
    }
}
