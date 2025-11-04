//
//  TimaiUITests.swift
//  Timai
//
//  Copyright (c) 2025 Dr. Thomas Entner.
//  All rights reserved.
//
//  Licensed under the Business Source License 1.1.
//  Usage is free for non-commercial and personal use.
//  Commercial use requires a commercial license.
//
import XCTest

class TimaiUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments += ["UI-Testing"]
        app.launch()
    }

    func testLaunch() {
        // Basic launch test
        XCTAssertTrue(app.exists)
    }

    override func tearDown() {
        app.launchArguments.removeAll()
        super.tearDown()
    }
}
