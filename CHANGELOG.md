# Changelog

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

## [Unreleased]

### Hinzugefügt
- **Live Activities**: Timer-Anzeige auf Lock Screen und Dynamic Island
  - Echtzeit-Timer auf dem Sperrbildschirm
  - Dynamic Island Integration für iPhone 14 Pro und neuer
  - Projekt-Kürzel in kompakter Ansicht
  - Pulsierendes Timer-Icon mit Gradient-Effekten
  - Expanded View zeigt Projekt, Activity, Kunde und Startzeit
- **Timer-Funktionalität**: 
  - Schneller Timer-Start via Floating Action Button
  - Timer-Start aus bestehendem Eintrag per Kontext-Menü
  - In-App Timer-Banner mit Live-Anzeige
  - Timer-Stop-Dialog mit optionaler Beschreibung
  - Timer-State überlebt App-Neustart
  - Integration mit Kimai API (laufende Timer ohne end-Datum)
- **Widget Extension**: Neues TimaiWidgets Target für Live Activities

### Hinzugefügt (vorherige Version)
- **Benutzer-Rollen-System**: Integration des `/api/users/me` Endpoints zur Abfrage von Benutzerrollen und -berechtigungen
- **Rollenbasierte Zugriffssteuerung**: Reports werden automatisch basierend auf den Benutzerberechtigungen gefiltert
  - Nur Admins und Super-Admins sehen "Alle Benutzer"-Reports
  - ROLE_USER sieht nur eigene Benutzer-Reports und Projekt-Reports
- **Zeitraum-Navigation in Reports**: Interaktiver DatePicker mit Vor/Zurück-Buttons
  - Wochenweise Navigation mit Kalenderwochenanzeige
  - Monatsweise Navigation mit deutschem Monatsnamen
  - Jahresweise Navigation
  - "Heute"-Button zum schnellen Zurückspringen zur aktuellen Periode
- **Account-Informationen in Einstellungen**: Neue Section zeigt Benutzerdetails
  - Benutzername und User-ID
  - Zugewiesene Rollen mit Checkmarks
  - Server-Endpoint-URL
- **Spenden-Button**: Neuer "Entwickler unterstützen"-Button in den Einstellungen mit PayPal.me-Link
- **Lazy Loading für Projekt-Budgets**: Budget-Daten werden jetzt erst bei Bedarf geladen
  - Drastisch reduzierte Ladezeiten für Reports
  - Keine abgebrochenen API-Requests mehr
  - Intelligentes Caching bereits geladener Budget-Daten

### Geändert
- **Verbesserte Report-Performance**: Reports laden jetzt sofort ohne auf Budget-Daten zu warten
- **Optimierte Fehlerbehandlung**: 403-Fehler beim Laden von User-Listen blockieren nicht mehr den gesamten Report-View
- **DatePicker-Stabilität**: Behoben dass DatePicker nach 2-3 Änderungen hängen blieb
  - Date-Range wird nur einmal beim Initialisieren berechnet
  - Validierung beim Navigieren zwischen Zeiträumen
  - Explizite Button-Styles zur Vermeidung von Event-Konflikten

### Behoben
- DatePicker friert nicht mehr nach mehrmaliger Benutzung ein
- 403-Fehler beim Abrufen der User-Liste führt nicht mehr zum Fehler im ReportsViewModel
- Alle 28 Projekt-Budget-Requests werden nicht mehr parallel beim Report-Start ausgeführt
- "Code=-999 Abgebrochen"-Fehler bei parallelen API-Requests eliminiert

### Technisch
- **Live Activities Architektur**:
  - `ActiveTimer` Model für Timer-State mit Elapsed-Time-Berechnung
  - `TimerActivityAttributes` für ActivityKit Integration
  - `TimerManager` Service mit Persistenz in UserDefaults
  - `LiveActivityManager` für Activity Lifecycle Management
  - Widget Extension Target mit iOS 17+ Support
- **Timer UI Komponenten**:
  - `TimerBanner` mit Echtzeit-Updates und Puls-Animation
  - `TimerStartSheet` mit Projekt-/Activity-Auswahl
  - `TimerStopDialog` mit Beschreibungs-Option
- **TimesheetView** erweitert:
  - FAB (Floating Action Button) für Timer-Start
  - Kontext-Menü mit "Timer starten" Option
  - Timer-Banner Integration
  - Timer-State Observierung
- `Info.plist` nutzt jetzt Build Settings Platzhalter (`$(MARKETING_VERSION)`, `$(CURRENT_PROJECT_VERSION)`)
- `TimesheetUser` Model erweitert um `roles: [String]?` Feld
- Neue Helper-Funktionen: `hasRole(_:)` und `hasAnyRole(_:)`
- `User` Model erweitert um `userDetails: TimesheetUser?`
- Neuer `NetworkService.getCurrentUser()` Endpoint
- `ReportsViewModel` mit Lazy-Loading-Funktionalität:
  - `loadProjectBudget(for:)` für on-demand Budget-Loading
  - `projectBudgetCache` für Performance-Optimierung
- `ProjectReportView` aufgeteilt in `ProjectReportView` und `ProjectRowView`
- `GenericTimeReportView` und `AllUsersReportView` mit optimiertem DateRange-Handling

---

## [1.0.0] - 2025-01-XX

### Hinzugefügt
- Initiale Version der Timai iOS App
- Zeiterfassung mit Kimai-Integration
- Offline-Unterstützung mit lokalem Cache
- Projekt-, Kunden- und Aktivitätsverwaltung
- Reports und Statistiken
- Mehrsprachige Unterstützung (Deutsch/Englisch)
- Dark Mode Support

---

## Legende

- **Hinzugefügt** für neue Features
- **Geändert** für Änderungen an bestehender Funktionalität
- **Veraltet** für Features, die bald entfernt werden
- **Entfernt** für entfernte Features
- **Behoben** für Bug-Fixes
- **Sicherheit** für Sicherheits-relevante Änderungen
- **Technisch** für technische/interne Änderungen
