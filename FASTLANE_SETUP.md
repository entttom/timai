# 🚀 Fastlane Setup - Schritt-für-Schritt-Anleitung

## Situation

Fastlane wurde für Ihr Timai-Projekt konfiguriert. Jetzt müssen Sie es installieren und einrichten.

## ⚠️ Ruby-Problem

Ihr Mac verwendet das System-Ruby, das sudo-Rechte für die Installation von Gems benötigt. Es gibt zwei Lösungen:

---

## 🎯 Lösung 1: Homebrew Ruby (EMPFOHLEN)

Diese Lösung ist sauberer und vermeidet sudo-Rechte:

### 1. Ruby über Homebrew installieren

```bash
# Homebrew installieren (falls noch nicht vorhanden)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Ruby installieren
brew install ruby

# Shell-Konfiguration aktualisieren (für zsh)
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="$HOME/.gem/ruby/3.3.0/bin:$PATH"' >> ~/.zshrc

# Shell neu laden
source ~/.zshrc
```

### 2. Ruby-Version prüfen

```bash
which ruby
ruby --version
# Sollte Ruby 3.x anzeigen, nicht das System-Ruby 2.6
```

### 3. Bundler aktualisieren

```bash
gem install bundler
```

### 4. Fastlane installieren

```bash
cd /Users/thomasentner/Github/timai
bundle install
```

### 5. Fastlane testen

```bash
bundle exec fastlane --version
```

✅ **Fertig! Fahren Sie mit "Nächste Schritte" unten fort.**

---

## 🎯 Lösung 2: Lokale Installation (Alternative)

Falls Sie kein Homebrew verwenden möchten:

### 1. Mit sudo installieren

```bash
cd /Users/thomasentner/Github/timai
sudo bundle install
# Passwort eingeben wenn gefragt
```

✅ **Fertig! Fahren Sie mit "Nächste Schritte" unten fort.**

---

## 📝 Nächste Schritte nach der Installation

### Schritt 1: Umgebungsvariablen einrichten

```bash
cd /Users/thomasentner/Github/timai

# Template in .env kopieren
cp fastlane/env.template fastlane/.env

# .env Datei bearbeiten
open fastlane/.env
# oder
nano fastlane/.env
```

**Tragen Sie folgende Werte ein:**

```bash
# Ihre Apple ID
APPLE_ID=ihre.email@example.com

# Team ID (zu finden unter https://developer.apple.com/account > Membership)
TEAM_ID=XXXXXXXXXX

# Match vorerst deaktiviert lassen
USE_MATCH=false
```

### Schritt 2: Ersten Test durchführen

```bash
# Tests ausführen
bundle exec fastlane test
```

Dieser Befehl wird:
- Xcode öffnen
- Tests im Simulator ausführen
- Ergebnisse anzeigen

### Schritt 3: Debug-Build erstellen

```bash
# Debug-Build erstellen (ohne App Store)
bundle exec fastlane debug
```

Dies erstellt eine `.ipa`-Datei in `fastlane/builds/`.

### Schritt 4: Build-Nummer erhöhen (optional)

```bash
# Build-Nummer erhöhen
bundle exec fastlane bump_build

# Version erhöhen (z.B. 1.0.0 -> 1.0.1)
bundle exec fastlane bump_version
```

---

## 🎨 Weitere nützliche Befehle

```bash
# Carthage Dependencies aktualisieren
bundle exec fastlane update_dependencies

# Ad-Hoc Build für interne Tests
bundle exec fastlane adhoc

# Alle verfügbaren Lanes anzeigen
bundle exec fastlane lanes
```

---

## 🚀 Beta-Deployment (TestFlight)

Wenn Sie bereit sind, zur TestFlight hochzuladen:

### Voraussetzungen:

1. Apple Developer Account (99€/Jahr)
2. App in App Store Connect erstellt
3. Certificates und Provisioning Profiles eingerichtet

### Befehl:

```bash
bundle exec fastlane beta
```

Dies wird:
- ✅ Build-Nummer automatisch erhöhen
- ✅ Release-Build erstellen
- ✅ Zu TestFlight hochladen
- ✅ Git-Commit und Tag erstellen

**Hinweis:** Beim ersten Mal werden Sie nach Ihrem Apple ID Passwort gefragt.

---

## 🔐 Certificate Management mit Match (Optional)

Match hilft, Certificates im Team zu teilen. Setup erst später:

```bash
bundle exec fastlane match init
```

Siehe ausführliche Anleitung in `fastlane/README.md`.

---

## ❓ Troubleshooting

### "Could not find gem 'fastlane'"

```bash
bundle install
```

### "Could not find action, lane or variable"

Stellen Sie sicher, dass Sie `bundle exec` verwenden:
```bash
bundle exec fastlane [lane]
```

### Certificate-Probleme

```bash
# Xcode Derived Data löschen
rm -rf ~/Library/Developer/Xcode/DerivedData

# Xcode neu öffnen
```

### Simulator startet nicht

```bash
# Alle Simulatoren zurücksetzen
xcrun simctl erase all
```

---

## 📚 Weitere Dokumentation

- **`fastlane/README.md`** - Ausführliche Dokumentation
- **[Fastlane Docs](https://docs.fastlane.tools)** - Offizielle Dokumentation
- **[Fastlane Actions](https://docs.fastlane.tools/actions/)** - Alle verfügbaren Actions

---

## ✅ Zusammenfassung

Nach der Installation können Sie:

1. ✅ **Tests automatisiert ausführen** - `bundle exec fastlane test`
2. ✅ **Builds erstellen** - `bundle exec fastlane debug`
3. ✅ **Versionsnummern verwalten** - `bundle exec fastlane bump_version`
4. ✅ **Zu TestFlight deployen** - `bundle exec fastlane beta`
5. ✅ **Zum App Store deployen** - `bundle exec fastlane release`

**Viel Erfolg! 🎉**


