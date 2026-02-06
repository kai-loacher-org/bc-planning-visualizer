/// <summary>
/// Temporäre Tabelle für Gantt-Abhängigkeiten.
/// Verbindet zwei Tasks (FA liefert Komponente für anderen FA).
/// </summary>
table 50101 "PV Gantt Dependency"
{
    Caption = 'Gantt Dependency';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "From Task ID"; Text[50])
        {
            Caption = 'From Task ID';
        }
        field(3; "To Task ID"; Text[50])
        {
            Caption = 'To Task ID';
        }
        field(10; "Component Item No."; Code[20])
        {
            Caption = 'Component Item No.';
        }
        field(11; Quantity; Decimal)
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
        key(FromTo; "From Task ID", "To Task ID")
        {
        }
    }
}
