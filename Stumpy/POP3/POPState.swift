//
//  POPState.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/3/21.
//

import Foundation

struct POPState: Equatable {
    let description: String
}

extension POPState {
    static let AUTHORIZATION = POPState(description: "AUTHORIZATION")
    static let TRANSACTION = POPState(description: "TRANSACTION")
    static let QUIT = POPState(description: "QUIT")
}
