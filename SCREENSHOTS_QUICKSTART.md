# 📸 Screenshots Schnellstart

## ✅ Alles ist bereits eingerichtet!

- ✅ UI-Tests konfiguriert
- ✅ SnapshotHelper.swift erstellt
- ✅ Snapfile für iPhone & iPad konfiguriert
- ✅ Fastlane Lane bereit

---

## 🚀 Screenshots erstellen - 3 Schritte

### Schritt 1: UI-Test anpassen (optional)

Bearbeiten Sie `TimaiUITests/TimaiUITests.swift`:

```swift
func testScreenshots() {
    sleep(2)
    
    // Screenshot vom Login-Screen
    snapshot("01-Login")
    
    // Hier weitere Screens hinzufügen...
}
```

**Tipp:** Vorerst funktioniert der Login-Screen-Screenshot bereits!

### Schritt 2: Screenshots erstellen

```bash
# Im Projektverzeichnis
cd /Users/thomasentner/Github/timai

# Screenshots für alle Geräte und Sprachen erstellen
bundle exec fastlane screenshots
```

Dies dauert ca. 5-10 Minuten (je nach Anzahl der Geräte).

### Schritt 3: Screenshots ansehen

```bash
# Öffne den Screenshots-Ordner
open fastlane/screenshots

# Oder HTML-Vorschau öffnen
open fastlane/screenshots/screenshots.html
```

---

## 📱 Was wird erstellt?

Screenshots für:
- **iPhone 16 Pro Max** (6.9" - erforderlich für App Store)
- **iPhone 16 Pro** (6.3" - erforderlich für App Store)
- **iPad Pro 13"** (13" - erforderlich für App Store)

In beiden Sprachen:
- 🇩🇪 Deutsch
- 🇬🇧 Englisch

---

## ⚡️ Schnell-Test (nur ein Gerät)

Für schnelles Testen mit nur einem Gerät:

```bash
bundle exec fastlane snapshot \
  --devices "iPhone 16 Pro" \
  --languages "de-DE"
```

Dies dauert nur ca. 1-2 Minuten.

---

## 📂 Output-Struktur

```
fastlane/screenshots/
├── screenshots.html          ← Vorschau aller Screenshots
├── de-DE/
│   ├── iPhone 16 Pro Max-01-Login.png
│   ├── iPhone 16 Pro-01-Login.png
│   └── iPad Pro 13-inch (M4)-01-Login.png
└── en-US/
    ├── iPhone 16 Pro Max-01-Login.png
    ├── iPhone 16 Pro-01-Login.png
    └── iPad Pro 13-inch (M4)-01-Login.png
```

---

## 🎯 Weitere Screenshots hinzufügen

### 1. UI-Elemente identifizieren

In Xcode → Accessibility Inspector oder direkt in SwiftUI:

```swift
// In Ihrer View
TextField("URL", text: $url)
    .accessibilityIdentifier("urlTextField")
```

### 2. UI-Test erweitern

```swift
func testScreenshots() {
    sleep(2)
    snapshot("01-Login")
    
    // Login durchführen
    let urlField = app.textFields["urlTextField"]
    if urlField.exists {
        urlField.tap()
        urlField.typeText("https://demo.kimai.org")
        
        app.buttons["loginButton"].tap()
        sleep(3)
        
        snapshot("02-Dashboard")
    }
}
```

### 3. Neue Screenshots erstellen

```bash
bundle exec fastlane screenshots
```

---

## 💡 Tipps

### Test-Daten verwenden

Für bessere Screenshots:
- Testen Sie mit Demo-Daten (z.B. https://demo.kimai.org)
- Bereiten Sie Test-Accounts vor
- Erstellen Sie aussagekräftige Beispiel-Einträge

### Wartezeiten optimieren

```swift
// Statt sleep(2)
let element = app.buttons["Login"]
XCTAssertTrue(element.waitForExistence(timeout: 5))
```

### Nur einzelne Screens

```swift
func testScreenshots_LoginOnly() {
    sleep(2)
    snapshot("01-Login")
}

func testScreenshots_Dashboard() {
    // Login durchführen
    performLogin()
    sleep(2)
    snapshot("02-Dashboard")
}
```

---

## 🐛 Troubleshooting

### Problem: "Device not found"

```bash
# Verfügbare Simulatoren anzeigen
xcrun simctl list devices available | grep "iPhone\|iPad"

# Snapfile mit korrektem Namen aktualisieren
```

### Problem: Screenshot ist leer

Erhöhen Sie die Wartezeit:
```swift
sleep(3)  // Mehr Zeit für die UI zum Laden
snapshot("screenshot-name")
```

### Problem: UI-Element nicht gefunden

```swift
// Prüfen ob Element existiert
if app.buttons["Login"].exists {
    app.buttons["Login"].tap()
}

// Mit Wartezeit
let button = app.buttons["Login"]
if button.waitForExistence(timeout: 5) {
    button.tap()
}
```

---

## 📚 Weitere Informationen

- **Vollständige Anleitung:** `SCREENSHOTS_ANLEITUNG.md`
- **Fastlane Docs:** https://docs.fastlane.tools/actions/snapshot/
- **UI-Test-Datei:** `TimaiUITests/TimaiUITests.swift`
- **Konfiguration:** `fastlane/Snapfile`

---

## ✅ Zusammenfassung

```bash
# 1. Screenshots erstellen
bundle exec fastlane screenshots

# 2. Ergebnis ansehen
open fastlane/screenshots/screenshots.html

# 3. Screenshots verwenden
# → Hochladen zu App Store Connect
```

**So einfach ist das! 🎉**


