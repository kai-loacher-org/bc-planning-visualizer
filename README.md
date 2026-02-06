# BC Planning Visualizer

**Visuelle Fertigungsplanung für Business Central**

## Das Problem

Der Business Central Planungsvorschlag (Requisition Worksheet / Planning Worksheet) ist ein mächtiges Werkzeug zur Berechnung von Bedarfen und Aufträgen. Allerdings fehlen entscheidende Komponenten:

1. **Abhängigkeiten** - Welcher FA hängt von welchem anderen FA ab?
2. **Zeitliche Perspektive** - Wann passiert was? In welcher Reihenfolge?
3. **Kapazitätsengpässe** - Welche Work Center sind überlastet?

### Aktuelle Situation

```
┌─────────────────────────────────────────────────────────────────┐
│  Planungsvorschlag                                              │
├─────────────────────────────────────────────────────────────────┤
│  Nr.   │ Artikel │ Menge │ Fällig    │ Aktion           │ Ref.  │
│  1     │ BIKE-01 │ 10    │ 15.03.26  │ Neuer FA         │       │
│  2     │ WHEEL-A │ 20    │ 12.03.26  │ Neuer FA         │       │
│  3     │ FRAME-X │ 10    │ 10.03.26  │ Neuer FA         │       │
│  4     │ SPOKE-1 │ 400   │ 08.03.26  │ Neuer Einkauf    │       │
│  5     │ TIRE-R  │ 20    │ 11.03.26  │ Ändern FA-0042   │       │
└─────────────────────────────────────────────────────────────────┘

❓ FA BIKE-01 braucht WHEEL-A und FRAME-X - aber in welcher zeitlichen Folge?
❓ WHEEL-A und FRAME-X laufen beide auf der CNC-Fräse - Konflikt?
❓ Was wenn die CNC-Fräse überlastet ist - was verschiebt sich alles?
```

**Was fehlt:**
- **FA → FA Abhängigkeiten** auf einen Blick
- **Gantt-Darstellung** mit zeitlicher Abfolge
- **Work Center Auslastung** und Bottlenecks
- **Kritischer Pfad** durch die Fertigungskette

## Lösungsansatz

### Vision: Gantt + Kapazitätsplanung

#### Ansicht 1: Gantt mit 3 Zoom-Stufen

##### 🔍 Tagesansicht (Stunden)
*Für die Feinplanung: Was läuft heute/morgen?*

```
                     Donnerstag, 10. März 2026
Work Center    │ 06  07  08  09  10  11  12  13  14  15  16  17 │
───────────────┼────────────────────────────────────────────────┤
CNC-Fräse      │     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░          │ 🔴
               │     │    FRAME-X Op.10       │WHEEL-A│          │
               │     └───────────────────────►└───┬───┘          │
               │                                  │              │
Lackiererei    │                         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓       │ 🟢
               │                         │ FRAME-X Op.20 │       │
               │     ◄───────────────────┘               │       │
───────────────┴────────────────────────────────────────────────┘
```

##### 📅 Wochenansicht (Tage)
*Für die Wochenplanung: Was steht diese/nächste Woche an?*

```
                          KW 10 - März 2026
Work Center    │  Mo    Di    Mi    Do    Fr    Sa    So  │
               │  09    10    11    12    13    14    15  │
───────────────┼──────────────────────────────────────────┤
CNC-Fräse      │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░              │ 🔴 140%
               │  │ FRAME-X   ││WHEEL-A │                 │
               │  └───────────┴┴───┬────┘                 │
               │                   │                      │
Montage        │                   └──────▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ 🟢 65%
               │                          │   BIKE-01    │
               │                          └──────────────►│
               │                                          │
Lackiererei    │        ▓▓▓▓▓▓▓▓▓▓                        │ 🟡 85%
               │        │FRAME-X │                        │
───────────────┴──────────────────────────────────────────┘
               [◀ KW 09]                          [KW 11 ▶]
```

##### 📆 Quartalsansicht (Wochen)
*Für die Grobplanung: Wie sieht das Quartal aus?*

```
                           Q1 2026
Work Center    │ KW1  KW2  KW3  KW4  KW5  KW6  KW7  KW8  KW9  KW10 KW11 KW12 │
───────────────┼─────────────────────────────────────────────────────────────┤
CNC-Fräse      │ ░░░  ▓▓▓  ▓▓   ▓▓▓  ▓▓▓  ░░░  ▓▓▓  ▓▓▓  ▓▓▓  ░░░  ▓▓   ▓▓▓ │
               │      ▲              ▲                   ▲    🔴              │
               │      │              │                   │ Überlast          │
               │                                                             │
Montage        │ ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓  │
               │                                              gleichmäßig 🟢 │
               │                                                             │
Lackiererei    │      ▓▓        ▓▓        ▓▓        ▓▓        ▓▓        ▓▓   │
               │                                         sporadisch 🟢       │
───────────────┴─────────────────────────────────────────────────────────────┘

Legende: ▓▓▓ = hoch ausgelastet   ▓▓ = normal   ░░░ = Überlast >100%
```

**Zoom-Buttons:**
```
[Heute] [Stunden ▼] [Tag] [Woche] [Monat] [Quartal]
```

#### Ansicht 2: Work Center Auslastung (Bottleneck-Analyse)

```
Work Center Auslastung KW 10-11

CNC-Fräse       ████████████████████████░░░░░░  140% 🔴 ENGPASS!
                ├─ FRAME-X (40h)
                ├─ WHEEL-A (24h)  ← Verschieben?
                └─ Wartung (8h)

Montage         ████████████████░░░░░░░░░░░░░░   65% 🟢
                └─ BIKE-01 (wartet auf CNC)

Lackiererei     █████████████████████░░░░░░░░░   85% 🟡
                └─ FRAME-X (nach CNC)

Schweißerei     ████████░░░░░░░░░░░░░░░░░░░░░░   35% 🟢
                └─ verfügbar
```

#### Ansicht 3: Kritischer Pfad

```
                    ┌─────────────────────────────────────────┐
                    │  Kritischer Pfad für BIKE-01            │
                    │  Gesamtdurchlaufzeit: 10 Tage           │
                    └─────────────────────────────────────────┘

    Einkauf          Fertigung            Montage
       │                 │                   │
   SPOKE-1 ──────► WHEEL-A ────┐             │
   (3 Tage)        (CNC 3T)    │             │
                               ├────► BIKE-01
                               │      (2 Tage)
              FRAME-X ─────────┘             │
              (CNC 4T + Lack 2T)             │
                   ▲                         │
                   │                         │
              ⚠️ ENGPASS                     ▼
              CNC-Fräse                  Auslieferung
                                         15.03.26
```

## Technische Optionen

### Option A: Control Add-In mit Gantt-Bibliothek ⭐ Empfohlen

Eine AL Extension mit einem JavaScript Control Add-In für Gantt + Kapazitätsansicht.

**Vorteile:**
- Direkt in BC integriert (eine Page für alles)
- Echtzeitdaten aus Prod. Orders, Work Centers, Routing
- Interaktiv: Drag & Drop zum Umplanen möglich

**Technologie-Stack:**
- AL Extension für BC
- Control Add-In (JavaScript)
- [DHTMLX Gantt](https://dhtmlx.com/docs/products/dhtmlxGantt/) oder [Frappe Gantt](https://frappe.io/gantt)
- [Chart.js](https://www.chartjs.org/) für Kapazitätsbalken

**Architektur:**
```
┌─────────────────────────────────────────────────────────────────┐
│  Business Central                                               │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Page: "Fertigungsplanung Visuell"                        │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  Control Add-In: Gantt Chart                        │  │ │
│  │  │  - FA als Balken                                    │  │ │
│  │  │  - Abhängigkeitslinien zwischen FAs                 │  │ │
│  │  │  - Gruppierung nach Work Center                     │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  Control Add-In: Kapazitätsübersicht                │  │ │
│  │  │  - Work Center Auslastung als Balken                │  │ │
│  │  │  - Rot wenn >100% (Bottleneck)                      │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                          ▲                                     │
│                          │ Daten                               │
│  ┌───────────────────────┴───────────────────────────────────┐ │
│  │  Codeunit: ProductionScheduleBuilder                      │ │
│  │  - Liest Prod. Order Lines + Routing Lines                │ │
│  │  - Berechnet Work Center Load                             │ │
│  │  - Findet FA → FA Abhängigkeiten (über Components)        │ │
│  │  - Ermittelt kritischen Pfad                              │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Datenquellen in BC:**
| Tabelle | Inhalt |
|---------|--------|
| `Prod. Order Line` | Fertigungsaufträge |
| `Prod. Order Routing Line` | Arbeitsschritte pro FA |
| `Prod. Order Component` | Komponenten → FA Abhängigkeiten |
| `Work Center` | Arbeitsplätze/Maschinen |
| `Calendar Entry` | Kapazität pro Work Center |
| `Capacity Ledger Entry` | Bereits gebuchte Kapazität |

### Option B: Externe Web-App (Next.js/React) ⭐ Alternative

Separate Web-App die per BC API die Daten holt. Mehr Flexibilität, aber separates Hosting.

**Vorteile:**
- Modernste UI/UX möglich
- Kann auch auf Tablet/Handy in der Werkstatt laufen
- Unabhängig von BC-Releases
- Kann offline arbeiten (PWA)

**Nachteile:**
- Separates Hosting nötig
- Authentifizierung komplexer (OAuth)
- Kein direkter "Zurück zu BC" Button

**Tech Stack:**
- Next.js + React
- TanStack Query für API-Calls
- Eine der Gantt-Libs (DHTMLX, Frappe, oder React-Gantt)
- BC OData/API v2.0 für Daten

### Option C: Power BI + Custom Visual

Power BI Report mit eingebettetem Gantt Visual.

**Vorteile:**
- Schnell aufgesetzt
- BC hat native Power BI Integration
- Historische Analysen möglich

**Nachteile:**
- Gantt Visuals in Power BI sind limitiert
- Keine echte Interaktion (kein Drag & Drop)
- Power BI Pro Lizenz nötig

## Empfehlung: Option A (BC Control Add-In) mit Phasenplan

### Phase 1: Datenmodell & API (1-2 Wochen)

**Ziel:** Alle nötigen Daten aus BC extrahieren können

1. **Codeunit: `ProductionScheduleBuilder`**
   - FA-Daten mit Start/Ende sammeln
   - Routing Lines → Arbeitsschritte pro Work Center
   - Komponenten analysieren → FA→FA Abhängigkeiten finden
   - Work Center Kapazität berechnen

2. **Output als JSON für das Frontend:**
   ```json
   {
     "tasks": [
       {"id": "FA001", "name": "BIKE-01", "start": "2026-03-10", "end": "2026-03-15", "workCenter": "Montage", "progress": 0},
       {"id": "FA002", "name": "WHEEL-A", "start": "2026-03-07", "end": "2026-03-12", "workCenter": "CNC", "progress": 0}
     ],
     "dependencies": [
       {"from": "FA002", "to": "FA001", "type": "finish-to-start"}
     ],
     "workCenterLoad": [
       {"workCenter": "CNC", "capacity": 40, "load": 56, "percent": 140}
     ]
   }
   ```

### Phase 2: Gantt Control Add-In (2-3 Wochen)

**Ziel:** Interaktives Gantt-Diagramm in BC

1. **Control Add-In mit DHTMLX Gantt oder Frappe Gantt**
   - FAs als Balken
   - Abhängigkeitslinien
   - Gruppierung nach Work Center
   - Farbcodierung: Normal / Verspätet / Kritisch

2. **Interaktion:**
   - Klick auf FA → Details in BC öffnen
   - Zoom: Tag / Woche / Monat
   - Filter nach Status, Work Center, Artikel

### Phase 3: Kapazitätsansicht (1-2 Wochen)

**Ziel:** Bottlenecks sofort erkennen

1. **Zweites Control Add-In oder Tab**
   - Balkendiagramm pro Work Center
   - Grün (<80%), Gelb (80-100%), Rot (>100%)
   - Klick auf Balken → zeigt betroffene FAs

2. **Bottleneck-Highlighting:**
   - Im Gantt werden überlastete Work Centers rot markiert
   - Vorschlag: "WHEEL-A um 2 Tage verschieben löst Engpass"

### Phase 4: Kritischer Pfad & What-If (optional)

**Ziel:** Proaktive Planung

1. **Kritischer Pfad berechnen und hervorheben**
2. **What-If Simulation:**
   - "Was passiert wenn CNC 2 Tage ausfällt?"
   - "Was wenn wir WHEEL-A vorziehen?"

## Datenmodell

### Gantt Task (für das Frontend)

```
┌─────────────────────────────────────────────────────────┐
│  GanttTask                                              │
├─────────────────────────────────────────────────────────┤
│  Id: Text[50]           // "FA-001" oder "FA-001-OP-10"│
│  Name: Text[100]        // "BIKE-01 Montage"           │
│  ItemNo: Code[20]                                       │
│  ProdOrderNo: Code[20]                                  │
│  OperationNo: Code[10]  // Arbeitsgang-Nr.             │
│  WorkCenterNo: Code[20]                                 │
│  WorkCenterName: Text[50]                               │
│  StartDateTime: DateTime                                │
│  EndDateTime: DateTime                                  │
│  DurationHours: Decimal                                 │
│  Progress: Decimal      // 0-100%                      │
│  Status: Enum (Planned|InProgress|Finished|Delayed)    │
│  IsCriticalPath: Boolean                                │
└─────────────────────────────────────────────────────────┘
```

### Dependency (FA → FA Verknüpfung)

```
┌─────────────────────────────────────────────────────────┐
│  GanttDependency                                        │
├─────────────────────────────────────────────────────────┤
│  FromTaskId: Text[50]   // FA der Komponente liefert   │
│  ToTaskId: Text[50]     // FA der Komponente braucht   │
│  Type: Enum (FinishToStart|StartToStart|etc.)          │
│  ComponentItemNo: Code[20]  // Welcher Artikel?        │
│  Quantity: Decimal                                      │
└─────────────────────────────────────────────────────────┘
```

### Work Center Load (Kapazitätsauslastung)

```
┌─────────────────────────────────────────────────────────┐
│  WorkCenterLoad                                         │
├─────────────────────────────────────────────────────────┤
│  WorkCenterNo: Code[20]                                 │
│  WorkCenterName: Text[50]                               │
│  PeriodStart: Date                                      │
│  PeriodEnd: Date                                        │
│  CapacityHours: Decimal     // Verfügbare Stunden      │
│  LoadHours: Decimal         // Geplante Stunden        │
│  LoadPercent: Decimal       // Load/Capacity * 100     │
│  Status: Enum (OK|Warning|Overload)                    │
│  AffectedProdOrders: List   // Welche FAs betroffen    │
└─────────────────────────────────────────────────────────┘
```

### BC-Tabellen die wir lesen

| BC Tabelle | Table ID | Was wir brauchen |
|------------|----------|------------------|
| `Production Order` | 5405 | FA Kopfdaten, Status |
| `Prod. Order Line` | 5406 | Artikel, Menge, Termine |
| `Prod. Order Routing Line` | 5409 | Arbeitsgänge, Work Center, Zeiten |
| `Prod. Order Component` | 5407 | Komponenten → FA-Abhängigkeiten |
| `Work Center` | 99000754 | Arbeitsplatz-Stammdaten |
| `Calendar Entry` | 99000757 | Verfügbare Kapazität |
| `Routing Link Code` | - | Verknüpfung Komponente ↔ Arbeitsgang |

## Nächste Schritte

1. [ ] **Spike:** Control Add-In mit vis.js in BC testen
2. [ ] **Analyse:** Welche Tabellen genau für Abhängigkeiten abfragen?
3. [ ] **Design:** Mockup der finalen Visualisierung
4. [ ] **MVP:** Textbasierte FactBox als Proof of Concept

## Lizenz

MIT License - siehe [LICENSE](LICENSE)

## Mitwirkende

- Max Loacher
- Kai (AI Assistant)
