//
//  MailStoreTests.swift
//  MailTests
//
//  Created by Stephen Beitzel on 12/31/20.
//

import XCTest
import Stumpy

class MailStoreTests: XCTestCase {

    var store: FixedSizeMailStore = FixedSizeMailStore(size: 10)

    override func setUpWithError() throws {
        store.clear()
    }

    override func tearDownWithError() throws {
        store.clear()
    }

    func testInitialStoreIsEmpty() {
        XCTAssert(store.messageCount == 0)
    }

    func testAddActuallyAdds() {
        let message = createMessage("Test message body")
        store.add(message: message)

        XCTAssert(store.messageCount == 1)
        let retrievedMessage = store.get(message: 0)
        XCTAssert(message.uid == retrievedMessage.uid)
        XCTAssert(message.byteStuff() == retrievedMessage.byteStuff())
    }

    func createMessage(_ body: String, subject: String = "Test subject") -> MailMessage {
        let message = MemoryMessage()
        message.append(line: body)
        message.add(value: "test@localhost", to: "Sender")
        message.add(value: "Test message", to: "Subject")
        message.add(value: "<\(message.uid)@localhost>", to: "Message-Id")
        return message
    }

    func testAddElevenYieldsTen() {
        for i in 0...11 { // swiftlint:disable:this identifier_name
            store.add(message: createMessage("Message number \(i)"))
        }
        XCTAssert(store.messageCount == 10)
        XCTAssert(store.numberOfMessages == 10)
    }
}
