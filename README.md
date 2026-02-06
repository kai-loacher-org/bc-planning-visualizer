# BC Planning Visualizer

**Visuelle Darstellung von Planungsvorschlag-Abhängigkeiten in Business Central**

## Das Problem

Der Business Central Planungsvorschlag (Requisition Worksheet / Planning Worksheet) ist ein mächtiges Werkzeug zur Berechnung von Bedarfen und Aufträgen. Allerdings fehlt eine entscheidende Komponente: **die visuelle Darstellung von Abhängigkeiten**.

### Aktuelle Situation

```
┌─────────────────────────────────────────────────────────────────┐
│  Planungsvorschlag                                              │
├─────────────────────────────────────────────────────────────────┤
│  Nr.   │ Artikel │ Menge │ Fällig    │ Aktion           │ Ref.  │
│  1     │ BIKE-01 │ 10    │ 15.03.26  │ Neuer FA         │       │
│  2     │ WHEEL-A │ 20    │ 12.03.26  │ Neuer FA         │       │
│  3     │ FRAME-X │ 10    │ 10.03.26  │ Neuer Einkauf    │       │
│  4     │ SPOKE-1 │ 400   │ 08.03.26  │ Neuer Einkauf    │       │
│  5     │ TIRE-R  │ 20    │ 11.03.26  │ Ändern FA-0042   │       │
└─────────────────────────────────────────────────────────────────┘

❓ Welche Zeilen hängen zusammen?
❓ Was passiert wenn sich Zeile 3 verzögert?
❓ Welche bestehenden Dokumente sind betroffen?
```

**Man sieht nicht:**
- Welche Planungszeilen voneinander abhängen
- Wie neue Aufträge mit bestehenden Dokumenten zusammenhängen
- Den kritischen Pfad durch die Fertigungskette
- Auswirkungen von Verzögerungen auf andere Positionen

## Lösungsansatz

### Vision: Interaktiver Abhängigkeitsgraph

```
                    ┌──────────────┐
                    │  BIKE-01     │
                    │  FA (neu)    │
                    │  15.03.26    │
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │  WHEEL-A     │ │  FRAME-X     │ │  SADDLE-01   │
    │  FA (neu)    │ │  EK (neu)    │ │  Bestand OK  │
    │  12.03.26    │ │  10.03.26    │ │  ✓           │
    └──────┬───────┘ └──────────────┘ └──────────────┘
           │
    ┌──────┴───────┐
    │              │
    ▼              ▼
┌──────────────┐ ┌──────────────┐
│  SPOKE-1     │ │  TIRE-R      │
│  EK (neu)    │ │  FA-0042     │
│  08.03.26    │ │  (ändern)    │
│  ⚠️ kritisch │ │  11.03.26    │
└──────────────┘ └──────────────┘
```

## Technische Optionen

### Option A: Control Add-In mit Graph-Bibliothek ⭐ Empfohlen

Eine AL Extension mit einem JavaScript Control Add-In für die Visualisierung.

**Vorteile:**
- Direkt in BC integriert
- Echtzeitdaten aus dem Planungsvorschlag
- Interaktiv (klicken, zoomen, filtern)

**Technologie-Stack:**
- AL Extension für BC
- Control Add-In (JavaScript)
- [vis.js Network](https://visjs.github.io/vis-network/) oder [D3.js](https://d3js.org/) für den Graph

**Architektur:**
```
┌─────────────────────────────────────────────────────────┐
│  Business Central                                       │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Page Extension: Planungsvorschlag                │ │
│  │  ┌─────────────────────────────────────────────┐  │ │
│  │  │  Control Add-In: Dependency Graph           │  │ │
│  │  │  ┌─────────────────────────────────────┐    │  │ │
│  │  │  │  vis.js / D3.js Visualisierung      │    │  │ │
│  │  │  └─────────────────────────────────────┘    │  │ │
│  │  └─────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────┘ │
│                          ▲                             │
│                          │ Daten                       │
│  ┌───────────────────────┴───────────────────────────┐ │
│  │  Codeunit: PlanningDependencyBuilder              │ │
│  │  - Analysiert Requisition Lines                   │ │
│  │  - Baut Abhängigkeitsbaum                         │ │
│  │  - Findet verknüpfte Dokumente                    │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Option B: Externe Web-App mit BC API

Eine separate Web-Anwendung die per OData/API die Daten aus BC holt.

**Vorteile:**
- Unabhängig von BC-Releases
- Modernere UI-Möglichkeiten
- Kann auch offline arbeiten (mit gecachten Daten)

**Nachteile:**
- Kein direkter Kontext zum Planungsvorschlag
- Zusätzliche Authentifizierung nötig
- Deployment/Hosting separat

### Option C: Power BI Report mit Custom Visual

Ein Power BI Report der die Planungsdaten visualisiert.

**Vorteile:**
- Einfach zu deployen (BC hat Power BI Integration)
- Kann auch historische Daten zeigen

**Nachteile:**
- Nicht so interaktiv
- Kein "Drill-Down" zurück in BC
- Power BI Lizenz erforderlich

## Empfehlung: Option A mit Phasenplan

### Phase 1: Proof of Concept (MVP)

**Ziel:** Zeigen dass es funktioniert

1. **Einfache Page mit FactBox**
   - Zeigt Abhängigkeiten der aktuell markierten Zeile
   - Textbasiert (Baumstruktur)
   
2. **Datensammlung aus:**
   - `Requisition Line` (Planungszeilen)
   - `Planning Component` (Komponenten für FA)
   - `Prod. Order Line` / `Purchase Line` (bestehende Dokumente)
   - `Item Ledger Entry` (Reservierungen)
   - `Reservation Entry` (Bedarfsverknüpfungen)

### Phase 2: Visuelle Komponente

**Ziel:** Graph-Darstellung

1. **Control Add-In erstellen**
   - vis.js Network für Graph
   - Knoten = Artikel/Dokumente
   - Kanten = Abhängigkeiten

2. **Features:**
   - Zoom & Pan
   - Knoten anklicken → Details
   - Farbcodierung nach Status
   - Kritischer Pfad hervorheben

### Phase 3: Vollständige Integration

**Ziel:** Produktionsreif

1. **Interaktivität:**
   - Aus Graph direkt in Dokument springen
   - Filter (nur neue, nur Änderungen, nur kritisch)
   - Zeitachsen-Ansicht

2. **Analyse-Features:**
   - "Was-wäre-wenn" Simulation
   - Engpass-Erkennung
   - Terminverschiebungs-Auswirkungen

## Datenmodell

```
┌─────────────────────────────────────────────────────────┐
│  PlanningDependencyNode                                 │
├─────────────────────────────────────────────────────────┤
│  NodeId: Guid                                           │
│  NodeType: Enum (ReqLine|ProdOrder|PurchOrder|Item)     │
│  ItemNo: Code[20]                                       │
│  Description: Text[100]                                 │
│  Quantity: Decimal                                      │
│  DueDate: Date                                          │
│  ActionType: Enum (New|Change|Cancel|None)              │
│  DocumentNo: Code[20]                                   │
│  Status: Enum (OK|Warning|Critical)                     │
│  Level: Integer  // Tiefe im Baum                       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  PlanningDependencyEdge                                 │
├─────────────────────────────────────────────────────────┤
│  FromNodeId: Guid                                       │
│  ToNodeId: Guid                                         │
│  EdgeType: Enum (Component|Reservation|OrderTracking)   │
│  Quantity: Decimal                                      │
└─────────────────────────────────────────────────────────┘
```

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
