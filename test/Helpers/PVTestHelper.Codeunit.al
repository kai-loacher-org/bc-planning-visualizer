/// <summary>
/// Helper Codeunit zum Erstellen von Testdaten für Planning Visualizer Tests.
/// </summary>
codeunit 50150 "PV Test Helper"
{
    /// <summary>
    /// Erstellt einen Fertigungsauftrag mit Routing für Tests.
    /// </summary>
    procedure CreateReleasedProdOrder(
        ItemNo: Code[20];
        Quantity: Decimal;
        DueDate: Date;
        WorkCenterNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Prod. Order erstellen
        ProductionOrder.Init();
        ProductionOrder.Status := ProductionOrder.Status::Released;
        ProductionOrder."No." := '';
        ProductionOrder.Insert(true);
        ProductionOrder.Validate("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.Validate("Source No.", ItemNo);
        ProductionOrder.Validate(Quantity, Quantity);
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);

        // Prod. Order Line
        ProdOrderLine.Init();
        ProdOrderLine.Status := ProductionOrder.Status;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Item No." := ItemNo;
        ProdOrderLine.Quantity := Quantity;
        ProdOrderLine."Due Date" := DueDate;
        ProdOrderLine."Starting Date" := CalcDate('<-1W>', DueDate);
        ProdOrderLine."Ending Date" := DueDate;
        ProdOrderLine.Insert();

        // Routing Line (ein Arbeitsgang)
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Status := ProductionOrder.Status;
        ProdOrderRoutingLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderRoutingLine."Routing Reference No." := ProdOrderLine."Line No.";
        ProdOrderRoutingLine."Routing No." := '';
        ProdOrderRoutingLine."Operation No." := '10';
        ProdOrderRoutingLine.Type := ProdOrderRoutingLine.Type::"Work Center";
        ProdOrderRoutingLine."No." := WorkCenterNo;
        ProdOrderRoutingLine."Work Center No." := WorkCenterNo;
        ProdOrderRoutingLine."Starting Date" := ProdOrderLine."Starting Date";
        ProdOrderRoutingLine."Starting Time" := 080000T;
        ProdOrderRoutingLine."Ending Date" := ProdOrderLine."Ending Date";
        ProdOrderRoutingLine."Ending Time" := 170000T;
        ProdOrderRoutingLine."Setup Time" := 1;
        ProdOrderRoutingLine."Run Time" := 8;
        ProdOrderRoutingLine.Insert();

        exit(ProductionOrder."No.");
    end;

    /// <summary>
    /// Erstellt ein Work Center für Tests.
    /// </summary>
    procedure CreateWorkCenter(Name: Text[100]): Code[20]
    var
        WorkCenter: Record "Work Center";
        WorkCenterGroup: Record "Work Center Group";
    begin
        // Work Center Group anlegen falls nicht vorhanden
        if not WorkCenterGroup.Get('TEST') then begin
            WorkCenterGroup.Init();
            WorkCenterGroup.Code := 'TEST';
            WorkCenterGroup.Name := 'Test Work Center Group';
            WorkCenterGroup.Insert();
        end;

        WorkCenter.Init();
        WorkCenter."No." := '';
        WorkCenter.Insert(true);
        WorkCenter.Name := Name;
        WorkCenter."Work Center Group Code" := 'TEST';
        WorkCenter.Capacity := 1;
        WorkCenter.Efficiency := 100;
        WorkCenter.Modify();

        // Kalender-Einträge für die nächsten 4 Wochen
        CreateCalendarEntries(WorkCenter."No.", Today, CalcDate('<+4W>', Today));

        exit(WorkCenter."No.");
    end;

    /// <summary>
    /// Erstellt einen Test-Artikel für die Fertigung.
    /// </summary>
    procedure CreateManufacturingItem(Description: Text[100]): Code[20]
    var
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Posting Groups holen (erste verfügbare)
        InventoryPostingGroup.FindFirst();
        GenProdPostingGroup.FindFirst();

        Item.Init();
        Item."No." := '';
        Item.Insert(true);
        Item.Description := Description;
        Item.Type := Item.Type::Inventory;
        Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        Item."Inventory Posting Group" := InventoryPostingGroup.Code;
        Item."Gen. Prod. Posting Group" := GenProdPostingGroup.Code;
        Item.Modify();

        exit(Item."No.");
    end;

    /// <summary>
    /// Fügt eine Komponente zu einem Fertigungsauftrag hinzu.
    /// </summary>
    procedure AddComponentToProdOrder(
        ProdOrderNo: Code[20];
        ComponentItemNo: Code[20];
        Quantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();

        ProdOrderComponent.Init();
        ProdOrderComponent.Status := ProdOrderLine.Status;
        ProdOrderComponent."Prod. Order No." := ProdOrderNo;
        ProdOrderComponent."Prod. Order Line No." := ProdOrderLine."Line No.";
        ProdOrderComponent."Line No." := GetNextComponentLineNo(ProdOrderNo, ProdOrderLine."Line No.");
        ProdOrderComponent."Item No." := ComponentItemNo;
        ProdOrderComponent."Expected Quantity" := Quantity;
        ProdOrderComponent."Quantity per" := Quantity;
        ProdOrderComponent."Due Date" := ProdOrderLine."Starting Date";
        ProdOrderComponent.Insert();
    end;

    local procedure CreateCalendarEntries(WorkCenterNo: Code[20]; FromDate: Date; ToDate: Date)
    var
        CalendarEntry: Record "Calendar Entry";
        CurrentDate: Date;
    begin
        CurrentDate := FromDate;
        while CurrentDate <= ToDate do begin
            // Nur Werktage (Mo-Fr)
            if Date2DWY(CurrentDate, 1) in [1 .. 5] then begin
                CalendarEntry.Init();
                CalendarEntry."Capacity Type" := CalendarEntry."Capacity Type"::"Work Center";
                CalendarEntry."No." := WorkCenterNo;
                CalendarEntry.Date := CurrentDate;
                CalendarEntry."Starting Time" := 080000T;
                CalendarEntry."Ending Time" := 170000T;
                CalendarEntry.Capacity := 1;
                CalendarEntry.Efficiency := 100;
                CalendarEntry."Capacity (Total)" := 8; // 8 Stunden pro Tag
                CalendarEntry."Capacity (Effective)" := 8;
                if CalendarEntry.Insert() then;
            end;
            CurrentDate := CurrentDate + 1;
        end;
    end;

    local procedure GetNextComponentLineNo(ProdOrderNo: Code[20]; ProdOrderLineNo: Integer): Integer
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLineNo);
        if ProdOrderComponent.FindLast() then
            exit(ProdOrderComponent."Line No." + 10000)
        else
            exit(10000);
    end;

    /// <summary>
    /// Löscht alle Testdaten.
    /// </summary>
    procedure CleanupTestData()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        Item: Record Item;
    begin
        // Prod. Orders mit 'TEST' im Source No.
        ProductionOrder.SetFilter("Source No.", '@*TEST*');
        ProductionOrder.DeleteAll(true);

        // Test Work Centers
        WorkCenter.SetFilter(Name, '@*TEST*');
        WorkCenter.DeleteAll(true);

        // Test Items  
        Item.SetFilter(Description, '@*TEST*');
        Item.DeleteAll(true);
    end;
}
