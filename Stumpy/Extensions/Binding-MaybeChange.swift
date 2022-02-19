//
//  Binding-MaybeChange.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 2/18/22.
//

import SwiftUI

extension Binding {
    func maybeChange(_ handler: @escaping (Value) -> Bool) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                if handler(newValue) {
                    self.wrappedValue = newValue
                }
            }
        )
    }
}
