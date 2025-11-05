# 🔍 UI-Element-Namen herausfinden - Anleitung

## Methode 1: UI-Recording in Xcode (EMPFOHLEN) ⭐

### Schritt 1: Xcode öffnen
```
1. Öffne Timai.xcodeproj in Xcode
2. Navigiere zu: TimaiUITests/TimaiUITests.swift
```

### Schritt 2: Recording starten
```
1. Klicke in eine Test-Funktion (z.B. testScreenshots)
2. Cursor auf eine leere Zeile setzen
3. Klicke auf den ROTEN RECORD-Button unten links im Editor
   (oder drücke ⌘+U und dann den Record-Button)
```

### Schritt 3: App bedienen
```
1. Der Simulator startet automatisch
2. Tippe auf Felder, Buttons, etc.
3. Xcode generiert automatisch den Code!
4. Stop-Button drücken wenn fertig
```

### Schritt 4: Code kopieren
```swift
// Xcode generiert Code wie:
app.textFields["https://demo.kimai.org/api/"].tap()
app.secureTextFields["API Token"].tap()
app.buttons["Anmelden"].tap()
```

---

## Methode 2: Accessibility Inspector (für Details)

### macOS Accessibility Inspector:
```
1. Xcode → Open Developer Tool → Accessibility Inspector
2. App im Simulator starten
3. Im Inspector das Ziel-Icon anklicken
4. Auf Element im Simulator klicken
5. Siehe "Identifier", "Label", "Traits"
```

---

## Methode 3: Mit Placeholder/Label-Text

Wenn keine Accessibility-IDs gesetzt sind, nutzt XCUITest:
- TextField: Placeholder-Text
- SecureField: Placeholder-Text  
- Button: Button-Text
- Tab: Tab-Text

### In Ihrer LoginView:
```swift
TextField("https://demo.kimai.org/api/", text: $kimaiURL)
// → Zugriff: app.textFields["https://demo.kimai.org/api/"]

SecureField("API Token", text: $apiToken)
// → Zugriff: app.secureTextFields["API Token"]

Text("Anmelden")
// → Zugriff: app.buttons["Anmelden"]
```

---

## ✅ EMPFEHLUNG: Accessibility IDs setzen

Für robustere Tests, Accessibility IDs hinzufügen:

### In LoginView.swift:
```swift
TextField("https://demo.kimai.org/api/", text: $kimaiURL)
    .accessibilityIdentifier("urlTextField")

SecureField("API Token", text: $apiToken)
    .accessibilityIdentifier("tokenTextField")
    
Button(action: performLogin) {
    Text("Anmelden")
}
.accessibilityIdentifier("loginButton")
```

### In UI-Tests dann:
```swift
app.textFields["urlTextField"].tap()
app.secureTextFields["tokenTextField"].tap()
app.buttons["loginButton"].tap()
```

**Vorteil:** Funktioniert auch wenn sich der Text ändert!

---

## 📱 Tab-Namen finden

### In MainTabView.swift:
```swift
.tabItem {
    Image(systemName: "clock.badge.checkmark")
    Text("Zeiterfassung")
}
```

**Zugriff im Test:**
```swift
app.tabBars.buttons["Zeiterfassung"].tap()
```

---

## 🎯 Ihre spezifischen Felder:

| Element | Typ | Identifier/Text |
|---------|-----|-----------------|
| URL-Feld | TextField | `"https://demo.kimai.org/api/"` |
| Token-Feld | SecureField | `"API Token"` |
| Login-Button | Button | `"Anmelden"` |
| Tab: Zeiterfassung | TabButton | `"Zeiterfassung"` |
| Tab: Reports | TabButton | Siehe Localized String |
| Tab: Einstellungen | TabButton | `"Einstellungen"` |

---

## 💡 TIPP: UI-Test Debug

Wenn ein Element nicht gefunden wird:

```swift
// Alle verfügbaren Elemente ausgeben
print(app.debugDescription)

// Nur TextFields
print(app.textFields.debugDescription)

// Nur Buttons
print(app.buttons.debugDescription)
```


