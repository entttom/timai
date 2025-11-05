# ✅ Fastlane ist jetzt eingerichtet!

## 🎉 Was wurde installiert?

- ✅ Fastlane 2.228.0
- ✅ CocoaPods 1.16.2
- ✅ Alle Fastlane-Konfigurationsdateien
- ✅ 12 vorkonfigurierte Lanes (Workflows)

---

## 📝 NÄCHSTE SCHRITTE

### 1. Umgebungsvariablen einrichten (WICHTIG!)

Bearbeiten Sie die Datei `fastlane/.env`:

```bash
open fastlane/.env
```

**Tragen Sie mindestens ein:**

```bash
# Ihre Apple ID
APPLE_ID=ihre.email@example.com

# Team ID (von https://developer.apple.com/account > Membership)
TEAM_ID=XXXXXXXXXX

# Match deaktiviert lassen (vorerst)
USE_MATCH=false
```

### 2. Ersten Test durchführen

```bash
bundle exec fastlane test
```

Dies führt alle Tests im Simulator aus.

### 3. Debug-Build erstellen

```bash
bundle exec fastlane debug
```

Erstellt eine `.ipa`-Datei in `fastlane/builds/`.

---

## 🚀 VERFÜGBARE BEFEHLE

### Tests & Builds

```bash
# Tests ausführen
bundle exec fastlane test

# UI-Tests ausführen
bundle exec fastlane ui_test

# Debug-Build erstellen
bundle exec fastlane debug

# Ad-Hoc Build für interne Tests
bundle exec fastlane adhoc
```

### Beta & Release

```bash
# Zu TestFlight hochladen
bundle exec fastlane beta

# Zum App Store hochladen
bundle exec fastlane release
```

**Hinweis:** Für Beta und Release benötigen Sie:
- Apple Developer Account (99€/Jahr)
- App in App Store Connect erstellt
- Certificates und Provisioning Profiles

### Version Management

```bash
# Build-Nummer erhöhen (z.B. 1 -> 2)
bundle exec fastlane bump_build

# Version erhöhen
bundle exec fastlane bump_version              # 1.0.0 -> 1.0.1 (patch)
bundle exec fastlane bump_version type:minor   # 1.0.0 -> 1.1.0
bundle exec fastlane bump_version type:major   # 1.0.0 -> 2.0.0
```

### Dependencies & Tools

```bash
# Carthage Dependencies aktualisieren
bundle exec fastlane update_dependencies

# SwiftLint ausführen
bundle exec fastlane lint

# Screenshots erstellen
bundle exec fastlane screenshots

# Alle verfügbaren Lanes anzeigen
bundle exec fastlane lanes
```

---

## 📂 PROJEKTSTRUKTUR

```
timai/
├── Gemfile                         # Ruby Dependencies
├── fastlane/
│   ├── Fastfile                    # Hauptkonfiguration (alle Lanes)
│   ├── Appfile                     # App-Konfiguration (Bundle ID, etc.)
│   ├── Matchfile                   # Certificate Management
│   ├── Snapfile                    # Screenshot-Konfiguration
│   ├── .env                        # Ihre Credentials (NICHT ins Git!)
│   ├── env.template                # Template für .env
│   └── README.md                   # Ausführliche Dokumentation
├── .bundle/config                  # Bundle-Konfiguration
└── vendor/bundle/                  # Installierte Gems (NICHT ins Git!)
```

---

## 🎯 TYPISCHER WORKFLOW

### Lokale Entwicklung

```bash
# 1. Änderungen machen
# ... Code bearbeiten ...

# 2. Tests ausführen
bundle exec fastlane test

# 3. Build erstellen
bundle exec fastlane debug
```

### Beta-Deployment

```bash
# 1. Änderungen committen
git add .
git commit -m "New feature"

# 2. Zu TestFlight hochladen
bundle exec fastlane beta

# Dies wird automatisch:
# - Build-Nummer erhöhen
# - Release-Build erstellen
# - Zu TestFlight hochladen
# - Git-Commit und Tag erstellen
```

### Release

```bash
# Version erhöhen
bundle exec fastlane bump_version type:minor

# Zum App Store hochladen
bundle exec fastlane release
```

---

## ⚠️ WICHTIGE HINWEISE

### Warnung: "Name of the lane 'debug' is already taken"

Dies ist eine harmlose Warnung, weil Fastlane bereits eine Action namens "debug" hat. Die Lane funktioniert trotzdem einwandfrei.

### .gitignore

Folgende Dateien/Ordner werden automatisch ignoriert:
- `vendor/bundle/` - Installierte Gems
- `fastlane/.env` - Ihre Credentials
- `fastlane/builds/` - Erstellte Builds
- `fastlane/screenshots/` - Generierte Screenshots

### Erste TestFlight-Upload

Beim ersten Mal werden Sie nach Ihrem Apple ID Passwort gefragt. Das ist normal.

---

## 📚 WEITERE INFORMATIONEN

- **`fastlane/README.md`** - Ausführliche Dokumentation mit Troubleshooting
- **`FASTLANE_SETUP.md`** - Detaillierte Setup-Anleitung
- **[Fastlane Docs](https://docs.fastlane.tools)** - Offizielle Dokumentation

---

## 🆘 PROBLEME?

### "Could not find gem 'fastlane'"

```bash
bundle install
```

### "Command not found: bundle"

```bash
gem install bundler
```

### Certificate-Probleme

```bash
# Xcode Derived Data löschen
rm -rf ~/Library/Developer/Xcode/DerivedData

# Xcode neu öffnen
```

### Tests schlagen fehl

```bash
# Simulatoren zurücksetzen
xcrun simctl erase all
```

---

## ✅ ZUSAMMENFASSUNG

Sie können jetzt:

1. ✅ **Tests automatisiert ausführen** - `bundle exec fastlane test`
2. ✅ **Builds erstellen** - `bundle exec fastlane debug`
3. ✅ **Versionsnummern verwalten** - `bundle exec fastlane bump_version`
4. ✅ **Zu TestFlight deployen** - `bundle exec fastlane beta` (nach .env-Konfiguration)
5. ✅ **Zum App Store deployen** - `bundle exec fastlane release`

**Viel Erfolg mit Fastlane! 🚀**


