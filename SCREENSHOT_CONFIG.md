# 📸 Screenshot-Konfiguration - Komplette Übersicht

## 🎯 Wo wird WAS konfiguriert?

Es gibt **2 Haupt-Konfigurationsdateien**:

---

## 1️⃣ **GERÄTE & SPRACHEN** 

### 📄 Datei: `fastlane/Snapfile`

**Was wird hier konfiguriert:**
- Für welche Geräte Screenshots erstellt werden
- In welchen Sprachen
- Wo Screenshots gespeichert werden
- Technische Einstellungen (Statusleiste, etc.)

### Beispiel:

```ruby
# GERÄTE - für welche iPhones/iPads?
devices([
  "iPhone 16 Pro Max",      # → Screenshot für dieses Gerät
  "iPhone 16 Pro",          # → Screenshot für dieses Gerät
  "iPad Pro 13-inch (M4)"   # → Screenshot für dieses Gerät
])

# SPRACHEN - in welchen Sprachen?
languages([
  "de-DE",  # → App wird auf Deutsch getestet
  "en-US"   # → App wird auf Englisch getestet
])

# OUTPUT - wo werden Screenshots gespeichert?
output_directory("./fastlane/screenshots")
```

**Ergebnis:** 
- 3 Geräte × 2 Sprachen = **6 Sets von Screenshots**
- Jedes Set enthält die Screenshots, die im UI-Test definiert sind

---

## 2️⃣ **WELCHE SCREENS** 

### 📄 Datei: `TimaiUITests/TimaiUITests.swift`

**Was wird hier konfiguriert:**
- WELCHE Screens/Views fotografiert werden
- WIE man zu diesen Screens navigiert
- WIE die Screenshots benannt werden

### Beispiel:

```swift
func testScreenshots() {
    sleep(2)
    
    // Screenshot 1: Login-Screen
    snapshot("01-Login")              // ← ERSTELLT Screenshot "01-Login"
    
    // Navigation zum Dashboard
    performLogin()
    sleep(2)
    
    // Screenshot 2: Dashboard
    snapshot("02-Dashboard")          // ← ERSTELLT Screenshot "02-Dashboard"
    
    // Navigation zu Reports
    app.tabBars.buttons["Reports"].tap()
    sleep(1)
    
    // Screenshot 3: Reports
    snapshot("03-Reports")            // ← ERSTELLT Screenshot "03-Reports"
}
```

**Ergebnis:**
- 3 Screenshots pro Gerät
- Benannt: `01-Login`, `02-Dashboard`, `03-Reports`

---

## 🔄 Wie arbeiten beide zusammen?

```
┌─────────────────────────────────────────────────────────┐
│                    fastlane/Snapfile                    │
│                                                         │
│  devices([                                              │
│    "iPhone 16 Pro Max",  ← Gerät 1                     │
│    "iPhone 16 Pro"       ← Gerät 2                     │
│  ])                                                     │
│                                                         │
│  languages([                                            │
│    "de-DE",  ← Sprache 1                               │
│    "en-US"   ← Sprache 2                               │
│  ])                                                     │
└─────────────────────────────────────────────────────────┘
                         ↓
        Fastlane startet für JEDE Kombination:
                         ↓
┌─────────────────────────────────────────────────────────┐
│              TimaiUITests/TimaiUITests.swift            │
│                                                         │
│  func testScreenshots() {                              │
│    snapshot("01-Login")      ← Screenshot 1            │
│    snapshot("02-Dashboard")  ← Screenshot 2            │
│    snapshot("03-Reports")    ← Screenshot 3            │
│  }                                                      │
└─────────────────────────────────────────────────────────┘
                         ↓
                    Ergebnis:
                         ↓
┌─────────────────────────────────────────────────────────┐
│              fastlane/screenshots/                      │
│                                                         │
│  de-DE/                                                 │
│    ├── iPhone 16 Pro Max-01-Login.png                  │
│    ├── iPhone 16 Pro Max-02-Dashboard.png              │
│    ├── iPhone 16 Pro Max-03-Reports.png                │
│    ├── iPhone 16 Pro-01-Login.png                      │
│    ├── iPhone 16 Pro-02-Dashboard.png                  │
│    └── iPhone 16 Pro-03-Reports.png                    │
│                                                         │
│  en-US/                                                 │
│    ├── iPhone 16 Pro Max-01-Login.png                  │
│    ├── iPhone 16 Pro Max-02-Dashboard.png              │
│    ├── iPhone 16 Pro Max-03-Reports.png                │
│    ├── iPhone 16 Pro-01-Login.png                      │
│    ├── iPhone 16 Pro-02-Dashboard.png                  │
│    └── iPhone 16 Pro-03-Reports.png                    │
└─────────────────────────────────────────────────────────┘

Total: 2 Geräte × 2 Sprachen × 3 Screenshots = 12 Dateien
```

---

## 📝 ZUSAMMENFASSUNG

### ❓ Welche Geräte?
➡️ **`fastlane/Snapfile`** → `devices([...])`

### ❓ Welche Sprachen?
➡️ **`fastlane/Snapfile`** → `languages([...])`

### ❓ Welche Screens?
➡️ **`TimaiUITests/TimaiUITests.swift`** → `snapshot("name")`

### ❓ Wo werden Screenshots gespeichert?
➡️ **`fastlane/Snapfile`** → `output_directory(...)`

### ❓ Wie werden Screenshots benannt?
➡️ **Format:** `{Gerätename}-{Screenshot-Name}.png`
➡️ **Beispiel:** `iPhone 16 Pro Max-01-Login.png`

---

## 🎯 PRAKTISCHE BEISPIELE

### Beispiel 1: Mehr Geräte hinzufügen

**Datei:** `fastlane/Snapfile`

```ruby
devices([
  "iPhone 16 Pro Max",
  "iPhone 16 Pro",
  "iPhone 16",              # ← NEU hinzugefügt
  "iPad Pro 13-inch (M4)",
  "iPad Pro 11-inch (M4)"   # ← NEU hinzugefügt
])
```

**Ergebnis:** Screenshots werden jetzt für 5 Geräte erstellt statt 3

---

### Beispiel 2: Mehr Sprachen hinzufügen

**Datei:** `fastlane/Snapfile`

```ruby
languages([
  "de-DE",
  "en-US",
  "fr-FR",  # ← Französisch hinzugefügt
  "es-ES"   # ← Spanisch hinzugefügt
])
```

**Ergebnis:** Screenshots werden jetzt in 4 Sprachen erstellt statt 2

---

### Beispiel 3: Mehr Screenshots hinzufügen

**Datei:** `TimaiUITests/TimaiUITests.swift`

```swift
func testScreenshots() {
    sleep(2)
    
    // Bestehende Screenshots
    snapshot("01-Login")
    
    performLogin()
    sleep(2)
    
    snapshot("02-Dashboard")
    
    // NEU: Weitere Screenshots hinzufügen
    app.tabBars.buttons["Reports"].tap()
    sleep(1)
    snapshot("03-Reports")                    // ← NEU
    
    app.tabBars.buttons["Settings"].tap()
    sleep(1)
    snapshot("04-Settings")                   // ← NEU
    
    // Timesheet erstellen
    app.buttons["New Timesheet"].tap()
    sleep(1)
    snapshot("05-New-Timesheet")              // ← NEU
}
```

**Ergebnis:** 5 Screenshots pro Gerät/Sprache statt 2

---

## 🔧 SCHRITT-FÜR-SCHRITT: Screenshot hinzufügen

### Schritt 1: UI-Test öffnen
```bash
open TimaiUITests/TimaiUITests.swift
```

### Schritt 2: Navigation zum gewünschten Screen
```swift
func testScreenshots() {
    snapshot("01-Login")
    
    // Zu neuem Screen navigieren
    app.buttons["Mein Button"].tap()
    sleep(1)
    
    // Screenshot machen
    snapshot("02-Neuer-Screen")  // ← Name frei wählbar!
}
```

### Schritt 3: Screenshots generieren
```bash
bundle exec fastlane screenshots
```

### Schritt 4: Prüfen
```bash
open fastlane/screenshots/screenshots.html
```

---

## 💡 TIPPS

### 1. Screenshot-Benennung

**Gut:**
```swift
snapshot("01-Login")
snapshot("02-Dashboard")
snapshot("03-Reports")
```

**Warum gut?**
- Nummeriert (sortiert sich automatisch)
- Beschreibend
- Keine Leerzeichen
- Englisch (international)

---

### 2. Nur bestimmte Geräte testen

**Während Entwicklung:**
```ruby
# In Snapfile
devices([
  "iPhone 16 Pro"  # Nur 1 Gerät = schneller
])
```

**Für App Store:**
```ruby
devices([
  "iPhone 16 Pro Max",  # Alle erforderlichen Geräte
  "iPhone 16 Pro",
  "iPad Pro 13-inch (M4)"
])
```

---

### 3. Debug: Einzelnen Screenshot testen

```swift
func testScreenshots_LoginOnly() {
    sleep(2)
    snapshot("01-Login")
    // Nur dieser eine Screenshot zum Testen
}
```

---

## 📊 MATRIX: Was wird erstellt?

| Geräte (Snapfile) | Sprachen (Snapfile) | Screenshots (UI-Test) | = Total |
|-------------------|---------------------|----------------------|---------|
| 2 | 2 | 1 | 4 Dateien |
| 3 | 2 | 1 | 6 Dateien |
| 3 | 2 | 5 | 30 Dateien |
| 5 | 4 | 10 | 200 Dateien |

**Formel:** `Geräte × Sprachen × Screenshots = Total Dateien`

---

## 🎓 WICHTIGE KONZEPTE

### snapshot("name") 
→ Macht einen Screenshot im aktuellen Zustand der App

### setupSnapshot(app)
→ Muss in `setUp()` aufgerufen werden (bereits erledigt ✅)

### sleep(2)
→ Wartezeit, damit UI geladen ist

### Accessibility Identifiers
→ Für stabile UI-Tests (optional aber empfohlen)

---

## ✅ CHECKLISTE

- [ ] `fastlane/Snapfile` - Geräte konfiguriert?
- [ ] `fastlane/Snapfile` - Sprachen konfiguriert?
- [ ] `TimaiUITests.swift` - Screenshots definiert?
- [ ] `setupSnapshot(app)` - In setUp() vorhanden?
- [ ] Test ausgeführt: `bundle exec fastlane screenshots`
- [ ] Screenshots geprüft: `open fastlane/screenshots/screenshots.html`

---

**Jetzt wissen Sie genau, wo was konfiguriert wird! 🎉**


