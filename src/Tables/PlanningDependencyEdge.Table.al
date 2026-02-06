/// <summary>
/// Temporäre Tabelle für Kanten im Abhängigkeitsgraph.
/// Verbindet zwei Knoten und zeigt die Art der Abhängigkeit.
/// </summary>
table 50101 "Planning Dependency Edge"
{
    Caption = 'Planning Dependency Edge';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; FromNodeId; Guid)
        {
            Caption = 'From Node ID';
        }
        field(2; ToNodeId; Guid)
        {
            Caption = 'To Node ID';
        }
        field(3; EdgeType; Enum "Dependency Edge Type")
        {
            Caption = 'Edge Type';
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(PK; FromNodeId, ToNodeId)
        {
            Clustered = true;
        }
    }
}
