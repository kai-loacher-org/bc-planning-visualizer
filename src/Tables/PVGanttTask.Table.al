/// <summary>
/// Temporäre Tabelle für Gantt-Tasks.
/// Repräsentiert einen Arbeitsgang aus einem Fertigungsauftrag.
/// </summary>
table 50100 "PV Gantt Task"
{
    Caption = 'Gantt Task';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Task ID"; Text[50])
        {
            Caption = 'Task ID';
        }
        field(3; "Task Name"; Text[100])
        {
            Caption = 'Task Name';
        }
        field(10; "Prod. Order Status"; Enum "Production Order Status")
        {
            Caption = 'Prod. Order Status';
        }
        field(11; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
        }
        field(12; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
        }
        field(13; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(21; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
        }
        field(30; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
        }
        field(31; "Work Center Name"; Text[100])
        {
            Caption = 'Work Center Name';
        }
        field(40; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';
        }
        field(41; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';
        }
        field(42; "Duration (Hours)"; Decimal)
        {
            Caption = 'Duration (Hours)';
            DecimalPlaces = 0 : 2;
        }
        field(50; "Progress %"; Decimal)
        {
            Caption = 'Progress %';
            MinValue = 0;
            MaxValue = 100;
        }
        field(51; Status; Enum "PV Gantt Task Status")
        {
            Caption = 'Status';
        }
        field(52; "Is Critical Path"; Boolean)
        {
            Caption = 'Is Critical Path';
        }
        field(60; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(TaskID; "Task ID")
        {
        }
        key(WorkCenter; "Work Center No.", "Starting Date-Time")
        {
        }
        key(ProdOrder; "Prod. Order No.", "Operation No.")
        {
        }
    }
}
