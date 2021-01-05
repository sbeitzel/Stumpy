//
//  POPResponse.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/4/21.
//

import Foundation

struct POPResponse {
    static let OK = "+OK"
    static let ERROR = "-ERR"

    let code: String
    let message: String
    let nextState: POPState
}
