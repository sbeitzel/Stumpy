
import SwiftUI

extension Binding {
    func validate(_ handler: @escaping (_ : Value) -> Bool) -> Binding<Value> {
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
