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

    var nameString: String {
        guard let name = name else {
            return "Unnamed server, capacity/SMTP/POP: \(mailSlots)/\(smtpPort)/\(popPort)"
        }
        return name
    }
}
