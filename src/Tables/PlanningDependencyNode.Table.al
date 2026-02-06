/// <summary>
/// Temporäre Tabelle für Knoten im Abhängigkeitsgraph.
/// Repräsentiert einen Artikel, ein Dokument oder eine Planungszeile.
/// </summary>
table 50100 "Planning Dependency Node"
{
    Caption = 'Planning Dependency Node';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; NodeId; Guid)
        {
            Caption = 'Node ID';
        }
        field(2; NodeType; Enum "Dependency Node Type")
        {
            Caption = 'Node Type';
        }
        field(3; ItemNo; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(6; DueDate; Date)
        {
            Caption = 'Due Date';
        }
        field(7; ActionType; Enum "Dependency Action Type")
        {
            Caption = 'Action Type';
        }
        field(8; DocumentNo; Code[20])
        {
            Caption = 'Document No.';
        }
        field(9; Status; Enum "Dependency Node Status")
        {
            Caption = 'Status';
        }
        field(10; Level; Integer)
        {
            Caption = 'Level';
            Description = 'Tiefe im Baum (0=Wurzel, positiv=downstream, negativ=upstream)';
        }
        field(11; ParentNodeId; Guid)
        {
            Caption = 'Parent Node ID';
        }
    }

    keys
    {
        key(PK; NodeId)
        {
            Clustered = true;
        }
        key(Level; Level, ItemNo)
        {
        }
    }
}
