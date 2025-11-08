# Widget Extension Provisioning Setup

## Problem
Das neue Widget Extension Target (`TimaiWidgets`) benötigt ein eigenes Provisioning Profile für Export/Distribution.

## Lösung

### 1. Matchfile aktualisiert ✅

Die `Matchfile` wurde bereits aktualisiert und enthält jetzt:
```ruby
app_identifier([
  "com.entner.time",
  "com.entner.time.TimaiWidgets"  # Neu!
])
```

### 2. Provisioning Profiles erstellen

**Lokal (wenn du Match verwendest):**

```bash
# Für Development
fastlane match development

# Für Ad-Hoc
fastlane match adhoc

# Für App Store
fastlane match appstore
```

Dies erstellt automatisch Provisioning Profiles für **beide** Bundle IDs.

### 3. In Apple Developer Portal (manuell)

Falls du **kein Match** verwendest, erstelle manuell:

1. Gehe zu: https://developer.apple.com/account/resources/profiles
2. **Neues Provisioning Profile** erstellen:
   - **App ID:** `com.entner.time.TimaiWidgets`
   - **Type:** App Store (oder Ad Hoc, Development je nach Bedarf)
   - **Certificates:** Dein Distribution Certificate auswählen
   - **Name:** "Timai Widgets App Store" (oder ähnlich)
3. **Download** und in Xcode importieren

### 4. Xcode Automatic Signing

Falls du **Automatic Signing** verwendest (empfohlen):

1. In Xcode → **TimaiWidgets** Target
2. **Signing & Capabilities** Tab
3. ✅ **Automatically manage signing** aktivieren
4. **Team** auswählen

Xcode erstellt dann automatisch die nötigen Profiles!

### 5. CI/CD System Konfiguration

**Für dein CI-System:**

Die Export-Options Dateien müssen aktualisiert werden um das Widget Extension zu inkludieren:

- `/Volumes/workspace/ci/development-exportoptions.plist`
- `/Volumes/workspace/ci/ad-hoc-exportoptions.plist`
- `/Volumes/workspace/ci/app-store-exportoptions.plist`

**Füge in jede Datei hinzu:**

```xml
<key>provisioningProfiles</key>
<dict>
    <key>com.entner.time</key>
    <string>DEIN_PROVISIONING_PROFILE_NAME</string>
    <key>com.entner.time.TimaiWidgets</key>
    <string>DEIN_WIDGET_PROVISIONING_PROFILE_NAME</string>
</dict>
```

### 6. Bundle Identifier prüfen

**In Xcode:**
1. Wähle **TimaiWidgetsExtension** Target
2. **General** Tab
3. Prüfe **Bundle Identifier** - sollte sein: `com.entner.time.TimaiWidgets`

## Schnellste Lösung

**Für CI/CD:**

Aktiviere **Automatic Signing** für beide Targets:
1. **Timai** Target → Signing & Capabilities → ✅ Automatically manage signing
2. **TimaiWidgetsExtension** Target → Signing & Capabilities → ✅ Automatically manage signing

Dann sollte der Export automatisch funktionieren!

## Export-Befehle testen (lokal)

```bash
# Archive erstellen
xcodebuild archive \
  -project Timai.xcodeproj \
  -scheme Timai \
  -archivePath ./build/Timai.xcarchive

# Export (App Store)
xcodebuild -exportArchive \
  -archivePath ./build/Timai.xcarchive \
  -exportPath ./build/export \
  -exportOptionsPlist ./fastlane/ExportOptions.plist
```

Falls Fehler auftreten, sind die Provisioning Profiles das Problem.

