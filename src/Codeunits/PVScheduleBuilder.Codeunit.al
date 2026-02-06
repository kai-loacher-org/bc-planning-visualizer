/// <summary>
/// Codeunit zum Aufbau der Fertigungsplanung für die Visualisierung.
/// Liest Prod. Orders, Routing Lines und berechnet Work Center Auslastung.
/// </summary>
codeunit 50100 "PV Schedule Builder"
{
    /// <summary>
    /// Baut die komplette Planungsübersicht für einen Zeitraum.
    /// </summary>
    /// <param name="FromDate">Startdatum des Zeitraums</param>
    /// <param name="ToDate">Enddatum des Zeitraums</param>
    /// <param name="TempGanttTask">Ausgabe: Gantt-Tasks</param>
    /// <param name="TempGanttDependency">Ausgabe: Abhängigkeiten</param>
    /// <param name="TempWorkCenterLoad">Ausgabe: Work Center Auslastung</param>
    procedure BuildSchedule(
        FromDate: Date;
        ToDate: Date;
        var TempGanttTask: Record "PV Gantt Task" temporary;
        var TempGanttDependency: Record "PV Gantt Dependency" temporary;
        var TempWorkCenterLoad: Record "PV Work Center Load" temporary)
    begin
        TempGanttTask.DeleteAll();
        TempGanttDependency.DeleteAll();
        TempWorkCenterLoad.DeleteAll();

        // 1. Alle relevanten Prod. Orders laden
        LoadProdOrderTasks(FromDate, ToDate, TempGanttTask);

        // 2. Abhängigkeiten aus Komponenten ermitteln
        FindDependencies(TempGanttTask, TempGanttDependency);

        // 3. Work Center Load berechnen
        CalculateWorkCenterLoad(FromDate, ToDate, TempGanttTask, TempWorkCenterLoad);
    end;

    local procedure LoadProdOrderTasks(
        FromDate: Date;
        ToDate: Date;
        var TempGanttTask: Record "PV Gantt Task" temporary)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        EntryNo: Integer;
    begin
        EntryNo := 0;

        // Nur geplante und freigegebene Fertigungsaufträge
        ProdOrderRoutingLine.SetFilter(Status, '%1|%2|%3',
            "Production Order Status"::Planned,
            "Production Order Status"::"Firm Planned",
            "Production Order Status"::Released);
        ProdOrderRoutingLine.SetFilter("Starting Date", '%1..%2', FromDate, ToDate);

        if ProdOrderRoutingLine.FindSet() then
            repeat
                // Prod. Order Line für Artikelinfo holen
                if ProdOrderLine.Get(
                    ProdOrderRoutingLine.Status,
                    ProdOrderRoutingLine."Prod. Order No.",
                    ProdOrderRoutingLine."Routing Reference No.")
                then begin
                    EntryNo += 1;
                    TempGanttTask.Init();
                    TempGanttTask."Entry No." := EntryNo;

                    // Task ID = "FA-Nr_OP-Nr" für Eindeutigkeit
                    TempGanttTask."Task ID" := StrSubstNo('%1_%2',
                        ProdOrderRoutingLine."Prod. Order No.",
                        ProdOrderRoutingLine."Operation No.");

                    TempGanttTask."Task Name" := StrSubstNo('%1 - %2',
                        ProdOrderLine."Item No.",
                        ProdOrderRoutingLine.Description);

                    // Prod. Order Referenz
                    TempGanttTask."Prod. Order Status" := ProdOrderRoutingLine.Status;
                    TempGanttTask."Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
                    TempGanttTask."Prod. Order Line No." := ProdOrderRoutingLine."Routing Reference No.";
                    TempGanttTask."Operation No." := ProdOrderRoutingLine."Operation No.";

                    // Artikel
                    TempGanttTask."Item No." := ProdOrderLine."Item No.";
                    TempGanttTask."Item Description" := ProdOrderLine.Description;
                    TempGanttTask.Quantity := ProdOrderLine.Quantity;

                    // Work Center
                    TempGanttTask."Work Center No." := ProdOrderRoutingLine."Work Center No.";
                    if WorkCenter.Get(ProdOrderRoutingLine."Work Center No.") then
                        TempGanttTask."Work Center Name" := WorkCenter.Name;

                    // Zeiten
                    TempGanttTask."Starting Date-Time" := CreateDateTime(
                        ProdOrderRoutingLine."Starting Date",
                        ProdOrderRoutingLine."Starting Time");
                    TempGanttTask."Ending Date-Time" := CreateDateTime(
                        ProdOrderRoutingLine."Ending Date",
                        ProdOrderRoutingLine."Ending Time");

                    // Dauer in Stunden
                    TempGanttTask."Duration (Hours)" := Round(
                        (TempGanttTask."Ending Date-Time" - TempGanttTask."Starting Date-Time") / 3600000,
                        0.01);

                    // Status bestimmen
                    TempGanttTask.Status := DetermineTaskStatus(ProdOrderRoutingLine);

                    // Fortschritt aus gebuchten Kapazitätsposten (vereinfacht)
                    TempGanttTask."Progress %" := CalculateProgress(ProdOrderRoutingLine);

                    TempGanttTask.Insert();
                end;
            until ProdOrderRoutingLine.Next() = 0;
    end;

    local procedure FindDependencies(
        var TempGanttTask: Record "PV Gantt Task" temporary;
        var TempGanttDependency: Record "PV Gantt Dependency" temporary)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        SupplyingTask: Record "PV Gantt Task" temporary;
        DependencyEntryNo: Integer;
    begin
        DependencyEntryNo := 0;

        // Für jeden Task: Komponenten prüfen
        TempGanttTask.Reset();
        if TempGanttTask.FindSet() then
            repeat
                // Komponenten dieses FA-Arbeitsgangs finden
                ProdOrderComponent.SetRange(Status, TempGanttTask."Prod. Order Status");
                ProdOrderComponent.SetRange("Prod. Order No.", TempGanttTask."Prod. Order No.");
                ProdOrderComponent.SetRange("Prod. Order Line No.", TempGanttTask."Prod. Order Line No.");

                if ProdOrderComponent.FindSet() then
                    repeat
                        // Gibt es einen anderen FA der diese Komponente produziert?
                        SupplyingTask.Reset();
                        SupplyingTask.Copy(TempGanttTask, true);
                        SupplyingTask.SetRange("Item No.", ProdOrderComponent."Item No.");
                        SupplyingTask.SetFilter("Prod. Order No.", '<>%1', TempGanttTask."Prod. Order No.");

                        if SupplyingTask.FindFirst() then begin
                            DependencyEntryNo += 1;
                            TempGanttDependency.Init();
                            TempGanttDependency."Entry No." := DependencyEntryNo;
                            TempGanttDependency."From Task ID" := SupplyingTask."Task ID";
                            TempGanttDependency."To Task ID" := TempGanttTask."Task ID";
                            TempGanttDependency."Component Item No." := ProdOrderComponent."Item No.";
                            TempGanttDependency.Quantity := ProdOrderComponent."Expected Quantity";
                            TempGanttDependency.Insert();
                        end;
                    until ProdOrderComponent.Next() = 0;
            until TempGanttTask.Next() = 0;
    end;

    local procedure CalculateWorkCenterLoad(
        FromDate: Date;
        ToDate: Date;
        var TempGanttTask: Record "PV Gantt Task" temporary;
        var TempWorkCenterLoad: Record "PV Work Center Load" temporary)
    var
        WorkCenter: Record "Work Center";
        CalendarEntry: Record "Calendar Entry";
        EntryNo: Integer;
        CurrentDate: Date;
        DailyCapacity: Decimal;
        DailyLoad: Decimal;
    begin
        EntryNo := 0;

        // Für jedes Work Center
        WorkCenter.SetFilter("No.", GetWorkCenterFilter(TempGanttTask));
        if WorkCenter.FindSet() then
            repeat
                // Für jede Woche im Zeitraum
                CurrentDate := CalcDate('<-CW>', FromDate); // Wochenanfang
                while CurrentDate <= ToDate do begin
                    EntryNo += 1;
                    TempWorkCenterLoad.Init();
                    TempWorkCenterLoad."Entry No." := EntryNo;
                    TempWorkCenterLoad."Work Center No." := WorkCenter."No.";
                    TempWorkCenterLoad."Work Center Name" := WorkCenter.Name;
                    TempWorkCenterLoad."Period Start" := CurrentDate;
                    TempWorkCenterLoad."Period End" := CalcDate('<+6D>', CurrentDate);

                    // Kapazität aus Calendar Entry summieren
                    TempWorkCenterLoad."Capacity (Hours)" := GetWeeklyCapacity(
                        WorkCenter."No.",
                        TempWorkCenterLoad."Period Start",
                        TempWorkCenterLoad."Period End");

                    // Last aus den Tasks summieren
                    TempWorkCenterLoad."Load (Hours)" := GetWeeklyLoad(
                        TempGanttTask,
                        WorkCenter."No.",
                        TempWorkCenterLoad."Period Start",
                        TempWorkCenterLoad."Period End");

                    TempWorkCenterLoad.CalculateLoadPercent();
                    TempWorkCenterLoad.Insert();

                    CurrentDate := CalcDate('<+7D>', CurrentDate);
                end;
            until WorkCenter.Next() = 0;
    end;

    local procedure DetermineTaskStatus(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Enum "PV Gantt Task Status"
    var
        RoutingStatus: Enum "Prod. Order Routing Status";
    begin
        case ProdOrderRoutingLine."Routing Status" of
            RoutingStatus::Planned, RoutingStatus::" ":
                begin
                    if ProdOrderRoutingLine."Starting Date" < Today then
                        exit("PV Gantt Task Status"::Delayed);
                    exit("PV Gantt Task Status"::Planned);
                end;
            RoutingStatus::"In Progress":
                exit("PV Gantt Task Status"::InProgress);
            RoutingStatus::Finished:
                exit("PV Gantt Task Status"::Finished);
            else
                exit("PV Gantt Task Status"::Planned);
        end;
    end;

    local procedure CalculateProgress(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        TotalTime: Decimal;
        BookedTime: Decimal;
    begin
        TotalTime := ProdOrderRoutingLine."Setup Time" + ProdOrderRoutingLine."Run Time";
        if TotalTime = 0 then
            exit(0);

        // Gebuchte Kapazität finden
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderRoutingLine."Prod. Order No.");
        CapacityLedgerEntry.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        CapacityLedgerEntry.CalcSums("Setup Time", "Run Time");
        BookedTime := CapacityLedgerEntry."Setup Time" + CapacityLedgerEntry."Run Time";

        exit(Round(BookedTime / TotalTime * 100, 1));
    end;

    local procedure GetWorkCenterFilter(var TempGanttTask: Record "PV Gantt Task" temporary): Text
    var
        FilterText: TextBuilder;
    begin
        TempGanttTask.Reset();
        if TempGanttTask.FindSet() then
            repeat
                if TempGanttTask."Work Center No." <> '' then begin
                    if FilterText.Length > 0 then
                        FilterText.Append('|');
                    FilterText.Append(TempGanttTask."Work Center No.");
                end;
            until TempGanttTask.Next() = 0;

        if FilterText.Length = 0 then
            exit('*');
        exit(FilterText.ToText());
    end;

    local procedure GetWeeklyCapacity(WorkCenterNo: Code[20]; FromDate: Date; ToDate: Date): Decimal
    var
        CalendarEntry: Record "Calendar Entry";
        TotalCapacity: Decimal;
    begin
        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Work Center");
        CalendarEntry.SetRange("No.", WorkCenterNo);
        CalendarEntry.SetRange(Date, FromDate, ToDate);
        CalendarEntry.CalcSums("Capacity (Total)");
        exit(CalendarEntry."Capacity (Total)");
    end;

    local procedure GetWeeklyLoad(
        var TempGanttTask: Record "PV Gantt Task" temporary;
        WorkCenterNo: Code[20];
        FromDate: Date;
        ToDate: Date): Decimal
    var
        TotalLoad: Decimal;
    begin
        TempGanttTask.Reset();
        TempGanttTask.SetRange("Work Center No.", WorkCenterNo);
        TempGanttTask.SetFilter("Starting Date-Time", '%1..%2',
            CreateDateTime(FromDate, 0T),
            CreateDateTime(ToDate, 235959T));

        if TempGanttTask.FindSet() then
            repeat
                TotalLoad += TempGanttTask."Duration (Hours)";
            until TempGanttTask.Next() = 0;

        exit(TotalLoad);
    end;
}
