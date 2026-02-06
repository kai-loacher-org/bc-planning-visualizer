/// <summary>
/// Codeunit für das Sammeln und Aufbauen von Planungsabhängigkeiten.
/// Analysiert Requisition Lines und findet alle verknüpften Dokumente.
/// </summary>
codeunit 50100 "Planning Dependency Builder"
{
    /// <summary>
    /// Baut den Abhängigkeitsbaum für eine einzelne Planungszeile.
    /// </summary>
    /// <param name="RequisitionLine">Die zu analysierende Planungszeile</param>
    /// <param name="TempDependencyNode">Temporäre Tabelle für die Knoten</param>
    /// <param name="TempDependencyEdge">Temporäre Tabelle für die Kanten</param>
    procedure BuildDependencyTree(
        RequisitionLine: Record "Requisition Line";
        var TempDependencyNode: Record "Planning Dependency Node" temporary;
        var TempDependencyEdge: Record "Planning Dependency Edge" temporary)
    var
        RootNodeId: Guid;
    begin
        // Hauptknoten für die Planungszeile erstellen
        RootNodeId := CreateNodeFromReqLine(RequisitionLine, TempDependencyNode, 0);

        // Abhängigkeiten nach unten (Komponenten/Bedarf) finden
        FindDownstreamDependencies(RequisitionLine, RootNodeId, TempDependencyNode, TempDependencyEdge, 1);

        // Abhängigkeiten nach oben (woher kommt der Bedarf?) finden
        FindUpstreamDependencies(RequisitionLine, RootNodeId, TempDependencyNode, TempDependencyEdge, -1);
    end;

    local procedure CreateNodeFromReqLine(
        RequisitionLine: Record "Requisition Line";
        var TempDependencyNode: Record "Planning Dependency Node" temporary;
        Level: Integer): Guid
    var
        NewNodeId: Guid;
    begin
        NewNodeId := CreateGuid();

        TempDependencyNode.Init();
        TempDependencyNode.NodeId := NewNodeId;
        TempDependencyNode.NodeType := TempDependencyNode.NodeType::ReqLine;
        TempDependencyNode.ItemNo := RequisitionLine."No.";
        TempDependencyNode.Description := RequisitionLine.Description;
        TempDependencyNode.Quantity := RequisitionLine.Quantity;
        TempDependencyNode.DueDate := RequisitionLine."Due Date";
        TempDependencyNode.ActionType := MapActionMessage(RequisitionLine."Action Message");
        TempDependencyNode.DocumentNo := RequisitionLine."Ref. Order No.";
        TempDependencyNode.Level := Level;
        TempDependencyNode.Status := DetermineNodeStatus(RequisitionLine);
        TempDependencyNode.Insert();

        exit(NewNodeId);
    end;

    local procedure FindDownstreamDependencies(
        RequisitionLine: Record "Requisition Line";
        ParentNodeId: Guid;
        var TempDependencyNode: Record "Planning Dependency Node" temporary;
        var TempDependencyEdge: Record "Planning Dependency Edge" temporary;
        Level: Integer)
    var
        PlanningComponent: Record "Planning Component";
        ChildNodeId: Guid;
    begin
        // Wenn es ein FA wird, dann Komponenten finden
        if RequisitionLine."Ref. Order Type" = RequisitionLine."Ref. Order Type"::"Prod. Order" then begin
            PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
            PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
            PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
            if PlanningComponent.FindSet() then
                repeat
                    ChildNodeId := CreateNodeFromComponent(PlanningComponent, TempDependencyNode, Level);
                    CreateEdge(ParentNodeId, ChildNodeId, TempDependencyEdge, "Dependency Edge Type"::Component, PlanningComponent."Expected Quantity");

                    // Rekursiv: Gibt es für diese Komponente auch eine Planungszeile?
                    FindRelatedReqLine(PlanningComponent, ChildNodeId, TempDependencyNode, TempDependencyEdge, Level + 1);
                until PlanningComponent.Next() = 0;
        end;
    end;

    local procedure FindUpstreamDependencies(
        RequisitionLine: Record "Requisition Line";
        ChildNodeId: Guid;
        var TempDependencyNode: Record "Planning Dependency Node" temporary;
        var TempDependencyEdge: Record "Planning Dependency Edge" temporary;
        Level: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
        ParentNodeId: Guid;
    begin
        // Wer braucht diesen Artikel? (Reservierungen nach oben)
        ReservationEntry.SetRange("Item No.", RequisitionLine."No.");
        ReservationEntry.SetRange("Source Type", Database::"Sales Line");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        if ReservationEntry.FindSet() then
            repeat
                ParentNodeId := CreateNodeFromReservation(ReservationEntry, TempDependencyNode, Level);
                CreateEdge(ParentNodeId, ChildNodeId, TempDependencyEdge, "Dependency Edge Type"::Reservation, ReservationEntry.Quantity);
            until ReservationEntry.Next() = 0;
    end;

    local procedure CreateNodeFromComponent(
        PlanningComponent: Record "Planning Component";
        var TempDependencyNode: Record "Planning Dependency Node" temporary;
        Level: Integer): Guid
    var
        NewNodeId: Guid;
    begin
        NewNodeId := CreateGuid();

        TempDependencyNode.Init();
        TempDependencyNode.NodeId := NewNodeId;
        TempDependencyNode.NodeType := TempDependencyNode.NodeType::Component;
        TempDependencyNode.ItemNo := PlanningComponent."Item No.";
        TempDependencyNode.Description := PlanningComponent.Description;
        TempDependencyNode.Quantity := PlanningComponent."Expected Quantity";
        TempDependencyNode.DueDate := PlanningComponent."Due Date";
        TempDependencyNode.Level := Level;
        TempDependencyNode.Insert();

        exit(NewNodeId);
    end;

    local procedure CreateNodeFromReservation(
        ReservationEntry: Record "Reservation Entry";
        var TempDependencyNode: Record "Planning Dependency Node" temporary;
        Level: Integer): Guid
    var
        NewNodeId: Guid;
    begin
        NewNodeId := CreateGuid();

        TempDependencyNode.Init();
        TempDependencyNode.NodeId := NewNodeId;
        TempDependencyNode.NodeType := TempDependencyNode.NodeType::Reservation;
        TempDependencyNode.ItemNo := ReservationEntry."Item No.";
        TempDependencyNode.Description := ReservationEntry.Description;
        TempDependencyNode.Quantity := ReservationEntry.Quantity;
        TempDependencyNode.DueDate := ReservationEntry."Expected Receipt Date";
        TempDependencyNode.DocumentNo := Format(ReservationEntry."Source ID");
        TempDependencyNode.Level := Level;
        TempDependencyNode.Insert();

        exit(NewNodeId);
    end;

    local procedure CreateEdge(
        FromNodeId: Guid;
        ToNodeId: Guid;
        var TempDependencyEdge: Record "Planning Dependency Edge" temporary;
        EdgeType: Enum "Dependency Edge Type";
        Qty: Decimal)
    begin
        TempDependencyEdge.Init();
        TempDependencyEdge.FromNodeId := FromNodeId;
        TempDependencyEdge.ToNodeId := ToNodeId;
        TempDependencyEdge.EdgeType := EdgeType;
        TempDependencyEdge.Quantity := Qty;
        TempDependencyEdge.Insert();
    end;

    local procedure FindRelatedReqLine(
        PlanningComponent: Record "Planning Component";
        ComponentNodeId: Guid;
        var TempDependencyNode: Record "Planning Dependency Node" temporary;
        var TempDependencyEdge: Record "Planning Dependency Edge" temporary;
        Level: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Suche ob es für diese Komponente eine eigene Planungszeile gibt
        RequisitionLine.SetRange("Worksheet Template Name", PlanningComponent."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", PlanningComponent."Worksheet Batch Name");
        RequisitionLine.SetRange("No.", PlanningComponent."Item No.");
        if RequisitionLine.FindFirst() then
            // Rekursiver Aufruf für verschachtelte Abhängigkeiten
            BuildDependencyTree(RequisitionLine, TempDependencyNode, TempDependencyEdge);
    end;

    local procedure MapActionMessage(ActionMessage: Enum "Action Message Type"): Enum "Dependency Action Type"
    begin
        case ActionMessage of
            ActionMessage::" ":
                exit("Dependency Action Type"::None);
            ActionMessage::New:
                exit("Dependency Action Type"::New);
            ActionMessage::"Change Qty.":
                exit("Dependency Action Type"::Change);
            ActionMessage::Reschedule:
                exit("Dependency Action Type"::Change);
            ActionMessage::"Resched. & Chg. Qty.":
                exit("Dependency Action Type"::Change);
            ActionMessage::Cancel:
                exit("Dependency Action Type"::Cancel);
            else
                exit("Dependency Action Type"::None);
        end;
    end;

    local procedure DetermineNodeStatus(RequisitionLine: Record "Requisition Line"): Enum "Dependency Node Status"
    begin
        // TODO: Logik für Statusbestimmung
        // - Kritisch wenn Lieferzeit nicht reicht
        // - Warnung wenn knapp
        // - OK sonst
        exit("Dependency Node Status"::OK);
    end;
}
