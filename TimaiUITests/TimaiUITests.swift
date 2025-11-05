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

@MainActor
class TimaiUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments += ["UI-Testing"]
        
        // Für Fastlane Screenshot-Generierung
        setupSnapshot(app)
        app.launch()
    }

    func testLaunch() {
        // Basic launch test
        XCTAssertTrue(app.exists)
    }
    
    // MARK: - Screenshot Tests für App Store
    
    func testScreenshots() {
        // Warte, bis die App geladen ist
        sleep(2)
        
        // Screenshot 1: Login-Screen
        snapshot("01-Login")
        
        // Login durchführen mit Demo-Credentials
        let urlField = app.textFields["https://demo.kimai.org/api/"]
        if urlField.exists {
            urlField.tap()
            urlField.typeText("https://demo.kimai.org/api/")
            
            let tokenField = app.secureTextFields["API Token"]
            tokenField.tap()
            tokenField.typeText("token_admin")
            
            // Auf Anmelden-Button klicken
            app.buttons["Anmelden"].tap()
            
            // Warten bis Login abgeschlossen ist (ca. 3-5 Sekunden)
            sleep(5)
            
            // Screenshot 2: Timesheet-Übersicht (Dashboard)
            snapshot("02-Timesheet-Overview")
            
            // Screenshot 3: Einen Eintrag öffnen
            // Warten bis Daten geladen sind
            sleep(2)
            
            if app.tables.cells.firstMatch.exists {
                app.tables.cells.firstMatch.tap()
                sleep(1)
                snapshot("03-Timesheet-Details")
                
                // Zurück navigieren
                app.navigationBars.buttons.firstMatch.tap()
                sleep(1)
            }
            
            // Screenshot 4: Reports Tab
            // Tab-Name ist lokalisiert: "Berichte" (DE) oder "Reports" (EN)
            let reportsTab = app.tabBars.buttons["Berichte"]
            if reportsTab.exists {
                reportsTab.tap()
            } else {
                // Fallback für Englisch
                app.tabBars.buttons["Reports"].tap()
            }
            sleep(2)
            snapshot("04-Reports")
            
            // Screenshot 5: Einstellungen Tab
            app.tabBars.buttons["Einstellungen"].tap()
            sleep(1)
            snapshot("05-Settings")
        }
    }

    override func tearDown() {
        app.launchArguments.removeAll()
        super.tearDown()
    }
}
