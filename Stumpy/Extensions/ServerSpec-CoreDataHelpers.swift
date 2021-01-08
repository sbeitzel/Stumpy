//
//  ServerSpec-CoreDataHelpers.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 1/8/21.
//

import Foundation

extension ServerSpec {
    var idString: String {
        guard let uid = specID else {
            return ""
        }
        return uid.uuidString
    }
}
