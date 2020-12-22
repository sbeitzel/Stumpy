//
//  ContentView.swift
//  Stumpy
//
//  Created by Stephen Beitzel on 12/21/20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var server: SMTPServer

    var body: some View {
        Text("Hello, World!")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SMTPServer(port: 4343))
    }
}
