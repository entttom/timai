# 📸 Screenshot-Test - Sofort loslegen!

## ✅ Alles ist fertig!

Ihr Screenshot-Test ist jetzt komplett konfiguriert:

### 📋 Was wird gemacht:

1. ✅ **Screenshot 1:** Login-Screen
2. ✅ **Login ausführen:**
   - URL: `https://demo.kimai.org/api/`
   - Token: `token_admin`
   - Button "Anmelden" klicken
3. ✅ **Screenshot 2:** Timesheet-Übersicht (Dashboard)
4. ✅ **Screenshot 3:** Einen Eintrag öffnen
5. ✅ **Screenshot 4:** Tab "Berichte" wechseln
6. ✅ **Screenshot 5:** Tab "Einstellungen"

---

## 🚀 Jetzt testen!

### Quick-Test (nur ein Gerät):

```bash
cd /Users/thomasentner/Github/timai
bundle exec fastlane snapshot --devices "iPhone 16 Pro" --languages "de-DE"
```

⏱️ **Dauert:** ca. 2-3 Minuten

---

### Vollständige Screenshots (alle Geräte):

```bash
bundle exec fastlane screenshots
```

⏱️ **Dauert:** ca. 10-15 Minuten

**Erstellt Screenshots für:**
- iPhone 16 Pro Max
- iPhone 16 Pro
- iPad Pro 13-inch
- Deutsch & Englisch

---

## 📂 Ergebnis ansehen

```bash
# HTML-Vorschau öffnen
open fastlane/screenshots/screenshots.html

# Oder Ordner öffnen
open fastlane/screenshots
```

---

## 🔍 Wie wurden die Feldnamen gefunden?

### Methode 1: Aus dem Code (was ich gemacht habe)

**LoginView.swift:**
```swift
TextField("https://demo.kimai.org/api/", text: $kimaiURL)
// → Placeholder-Text = Identifier im Test

SecureField("API Token", text: $apiToken)
// → Placeholder-Text = Identifier im Test

Button { ... } label: { Text("Anmelden") }
// → Button-Text = Identifier im Test
```

**MainTabView.swift:**
```swift
.tabItem { Text("Berichte") }
// → Tab-Text = Identifier im Test

.tabItem { Text("Einstellungen") }
// → Tab-Text = Identifier im Test
```

---

### Methode 2: UI-Recording (für zukünftige Tests)

**So finden Sie selbst Feldnamen:**

1. Öffne `TimaiUITests.swift` in Xcode
2. Klicke in `testScreenshots()` Funktion
3. Klicke auf den **ROTEN RECORD-BUTTON** (unten links)
4. Simulator startet → App bedienen (Felder antippen, etc.)
5. Xcode schreibt automatisch den Code!
6. Stop drücken → Code kopieren

**Beispiel-Output:**
```swift
app.textFields["https://demo.kimai.org/api/"].tap()
app.secureTextFields["API Token"].tap()
app.buttons["Anmelden"].tap()
```

---

## 💡 Tipps für UI-Tests

### 1. Element nicht gefunden?

**Debug-Ausgabe hinzufügen:**
```swift
// Alle Buttons ausgeben
print("Buttons:", app.buttons.allElementsBoundByIndex.map { $0.label })

// Alle TextFields ausgeben
print("TextFields:", app.textFields.allElementsBoundByIndex.map { $0.placeholderValue ?? "" })

// Alle Tabs ausgeben
print("Tabs:", app.tabBars.buttons.allElementsBoundByIndex.map { $0.label })
```

### 2. Wartezeiten anpassen

Wenn Login zu schnell/langsam ist:
```swift
// Statt sleep(5)
let dashboard = app.navigationBars["Zeiterfassung"]
XCTAssertTrue(dashboard.waitForExistence(timeout: 10))
```

### 3. Accessibility IDs hinzufügen (Optional)

Für robustere Tests in **LoginView.swift**:
```swift
TextField("https://demo.kimai.org/api/", text: $kimaiURL)
    .accessibilityIdentifier("urlTextField")

SecureField("API Token", text: $apiToken)
    .accessibilityIdentifier("tokenTextField")
```

Dann im Test:
```swift
app.textFields["urlTextField"].tap()  // ← Stabiler!
```

---

## 🐛 Troubleshooting

### Problem: Login schlägt fehl

**Lösung:** Wartezeit erhöhen
```swift
sleep(5)  // → sleep(10)
```

### Problem: Eintrag nicht gefunden

**Lösung:** Prüfen ob Daten geladen sind
```swift
sleep(2)  // Nach Login mehr warten
if app.tables.cells.firstMatch.exists {
    // ...
}
```

### Problem: Tab nicht gefunden

**Lösung:** Debug-Ausgabe
```swift
print("Verfügbare Tabs:", app.tabBars.buttons.allElementsBoundByIndex.map { $0.label })
```

---

## 📱 Screenshot-Flow im Detail

```
1. App startet
   ↓
2. Login-Screen erscheint
   ↓ snapshot("01-Login") ← Screenshot 1
   ↓
3. URL eingeben: https://demo.kimai.org/api/
   ↓
4. Token eingeben: token_admin
   ↓
5. "Anmelden" Button klicken
   ↓
6. Warten (5 Sek)
   ↓ snapshot("02-Timesheet-Overview") ← Screenshot 2
   ↓
7. Ersten Eintrag antippen
   ↓ snapshot("03-Timesheet-Details") ← Screenshot 3
   ↓
8. Zurück navigieren
   ↓
9. Tab "Berichte" antippen
   ↓ snapshot("04-Reports") ← Screenshot 4
   ↓
10. Tab "Einstellungen" antippen
    ↓ snapshot("05-Settings") ← Screenshot 5
    ↓
Fertig! ✅
```

---

## ✅ Zusammenfassung

### Quick-Test starten:
```bash
bundle exec fastlane snapshot --devices "iPhone 16 Pro" --languages "de-DE"
```

### Ergebnis ansehen:
```bash
open fastlane/screenshots/screenshots.html
```

### Bei Problemen:
- Siehe Troubleshooting oben
- Oder `UI_ELEMENTE_FINDEN.md` für Details

**Viel Erfolg! 📸**


