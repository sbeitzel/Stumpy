//
//  SessionState.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/1/21.
//

import Foundation

enum SMTPState {
    case connect, greet, mail, rcpt, data_hdr, data_body, quit
}
