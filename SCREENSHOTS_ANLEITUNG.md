# 📸 Automatische Screenshots mit Fastlane

Diese Anleitung zeigt Ihnen, wie Sie automatisch App Store Screenshots für Timai erstellen.

## 🎯 Was wurde eingerichtet?

✅ **UI-Test für Screenshots** (`TimaiUITests.swift`)
✅ **Snapfile-Konfiguration** für verschiedene Geräte
✅ **SnapshotHelper.swift** für die Screenshot-Funktion
✅ **Fastlane Lane** zum Erstellen der Screenshots

---

## 🚀 Screenshots erstellen

### Einfacher Befehl:

```bash
bundle exec fastlane screenshots
```

Dieser Befehl:
- Startet die App auf verschiedenen Simulatoren
- Führt die UI-Tests aus
- Erstellt Screenshots für jedes Gerät und jede Sprache
- Speichert die Screenshots in `fastlane/screenshots/`

---

## 📱 Unterstützte Geräte

Die Screenshots werden für folgende Geräte erstellt (entspricht App Store Anforderungen):

| Gerät | Display | Auflösung |
|-------|---------|-----------|
| iPhone 16 Pro Max | 6.9" | 2868 x 1320 |
| iPhone 16 Pro | 6.3" | 2622 x 1206 |
| iPhone SE (3. Gen) | 4.7" | 1334 x 750 |
| iPad Pro 13" (M4) | 13" | 2752 x 2064 |

### Sprachen:
- 🇩🇪 Deutsch (`de-DE`)
- 🇬🇧 Englisch (`en-US`)

---

## 📝 Screenshot-Test anpassen

Die Screenshot-Logik befindet sich in `TimaiUITests/TimaiUITests.swift`:

```swift
func testScreenshots() {
    // Warte, bis die App geladen ist
    sleep(2)
    
    // Screenshot 1: Login-Screen
    snapshot("01-Login")
    
    // Weitere Screenshots...
}
```

### Beispiel: Vollständige Screenshot-Tour

```swift
func testScreenshots() {
    sleep(2)
    
    // 1. Login-Screen
    snapshot("01-Login")
    
    // Login durchführen (mit Test-Credentials)
    let urlField = app.textFields["URL"]
    if urlField.exists {
        urlField.tap()
        urlField.typeText("https://demo.kimai.org")
        
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText("demo")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("demo")
        
        app.buttons["Login"].tap()
        sleep(3)
        
        // 2. Timesheet-Übersicht
        snapshot("02-Timesheet-Overview")
        
        // 3. Timesheet-Details
        if app.tables.cells.firstMatch.exists {
            app.tables.cells.firstMatch.tap()
            sleep(1)
            snapshot("03-Timesheet-Details")
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        // 4. Reports
        app.tabBars.buttons["Reports"].tap()
        sleep(1)
        snapshot("04-Reports")
        
        // 5. Settings
        app.tabBars.buttons["Einstellungen"].tap()
        sleep(1)
        snapshot("05-Settings")
    }
}
```

---

## 🎨 Screenshot-Dateien

Nach dem Erstellen finden Sie die Screenshots hier:

```
fastlane/screenshots/
├── de-DE/
│   ├── iPhone 16 Pro Max-01-Login.png
│   ├── iPhone 16 Pro Max-02-Timesheet-Overview.png
│   ├── iPhone 16 Pro-01-Login.png
│   ├── iPhone 16 Pro-02-Timesheet-Overview.png
│   ├── iPhone SE (3rd generation)-01-Login.png
│   └── iPad Pro (13-inch) (M4)-01-Login.png
└── en-US/
    ├── iPhone 16 Pro Max-01-Login.png
    ├── iPhone 16 Pro Max-02-Timesheet-Overview.png
    └── ...
```

---

## ⚙️ Snapfile anpassen

Die Konfiguration finden Sie in `fastlane/Snapfile`:

```ruby
# Andere Geräte hinzufügen
devices([
  "iPhone 16 Pro Max",
  "iPhone 16 Pro",
  "iPhone 16",  # Hinzufügen
  "iPhone SE (3rd generation)"
])

# Weitere Sprachen hinzufügen
languages([
  "de-DE",
  "en-US",
  "fr-FR",  # Französisch hinzufügen
  "es-ES"   # Spanisch hinzufügen
])

# Statusleiste anpassen
override_status_bar_arguments(
  "--time 9:41 " +
  "--dataNetwork wifi " +
  "--wifiBars 3 " +
  "--cellularMode active " +
  "--cellularBars 4 " +
  "--batteryState charged " +
  "--batteryLevel 100"
)
```

---

## 🎯 Workflow: Screenshots für App Store

### 1. Screenshots lokal testen

```bash
# Nur für ein Gerät und eine Sprache (schneller)
bundle exec fastlane snapshot --devices "iPhone 16 Pro" --languages "de-DE"
```

### 2. Vollständige Screenshots erstellen

```bash
bundle exec fastlane screenshots
```

### 3. Screenshots prüfen

```bash
# Screenshots-Ordner öffnen
open fastlane/screenshots
```

### 4. HTML-Vorschau ansehen

```bash
# Fastlane erstellt automatisch eine Vorschau
open fastlane/screenshots/screenshots.html
```

---

## 🛠 Verfügbare Geräte anzeigen

Um zu sehen, welche Simulatoren verfügbar sind:

```bash
xcrun simctl list devices available
```

Oder nur iOS-Geräte:

```bash
xcrun simctl list devices available | grep "iPhone\|iPad"
```

---

## 💡 Tipps & Tricks

### 1. Test-Daten vorbereiten

Erstellen Sie Test-Daten in der App, bevor Sie Screenshots machen:
- Test-Timesheet-Einträge
- Test-Projekte
- Test-Reports

### 2. Accessibility Identifiers verwenden

Fügen Sie in Ihren SwiftUI-Views Accessibility Identifiers hinzu:

```swift
TextField("URL", text: $url)
    .accessibilityIdentifier("urlTextField")

Button("Login") {
    login()
}
.accessibilityIdentifier("loginButton")
```

Dann in UI-Tests:

```swift
app.textFields["urlTextField"].tap()
app.buttons["loginButton"].tap()
```

### 3. Wartezeiten optimieren

Statt `sleep()` verwenden Sie:

```swift
// Warte auf Element
let element = app.buttons["Login"]
XCTAssertTrue(element.waitForExistence(timeout: 5))

// Warte auf App-Idle-Status
_ = XCTWaiter.wait(for: [expectation(description: "wait")], timeout: 1)
```

### 4. Parallele Ausführung

Für schnellere Screenshot-Erstellung:

```ruby
# In Snapfile
concurrent_simulators(true)
```

### 5. Nur bestimmte Geräte

```bash
bundle exec fastlane snapshot --devices "iPhone 16 Pro Max,iPhone 16 Pro"
```

---

## 🐛 Troubleshooting

### Problem: Simulator nicht gefunden

```bash
Error: Couldn't find simulator 'iPhone 16 Pro Max'
```

**Lösung:**
```bash
# Verfügbare Simulatoren anzeigen
xcrun simctl list devices available

# Snapfile mit korrektem Namen aktualisieren
```

### Problem: Test schlägt fehl

```bash
Error: UI Test failed
```

**Lösung:**
1. Test manuell in Xcode ausführen (⌘+U)
2. UI-Elemente prüfen (Accessibility Inspector)
3. Wartezeiten erhöhen

### Problem: Screenshots sind leer

**Lösung:**
```swift
// Genug Zeit geben, bis die UI geladen ist
sleep(2)  // oder waitForExistence()
snapshot("screenshot-name")
```

### Problem: Falsche Sprache

**Lösung:**
Prüfen Sie, dass Ihre App lokalisiert ist:
- `en.lproj/Localizable.strings`
- `de.lproj/Localizable.strings`

---

## 📚 Weitere Ressourcen

- [Fastlane Snapshot Dokumentation](https://docs.fastlane.tools/actions/snapshot/)
- [XCUITest Guide](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [App Store Screenshot Specs](https://help.apple.com/app-store-connect/#/devd274dd925)

---

## 📊 App Store Screenshot-Anforderungen

### iPhone
- **6.9" Display**: 2868 x 1320 (iPhone 16 Pro Max)
- **6.3" Display**: 2622 x 1206 (iPhone 16 Pro)
- **4.7" Display**: 1334 x 750 (iPhone SE)

### iPad
- **13" Display**: 2752 x 2064 (iPad Pro 13")
- **12.9" Display**: 2048 x 2732 (iPad Pro 12.9")

**Mindestens 3, maximal 10 Screenshots pro Gerätegröße erforderlich!**

---

## ✅ Zusammenfassung

1. **Screenshots erstellen:**
   ```bash
   bundle exec fastlane screenshots
   ```

2. **Test anpassen:**
   Bearbeiten Sie `TimaiUITests/TimaiUITests.swift`

3. **Konfiguration anpassen:**
   Bearbeiten Sie `fastlane/Snapfile`

4. **Screenshots prüfen:**
   ```bash
   open fastlane/screenshots/screenshots.html
   ```

**Viel Erfolg mit Ihren App Store Screenshots! 📸**


