/// <summary>
/// Aktionstyp für einen Knoten (was soll passieren).
/// </summary>
enum 50102 "Dependency Action Type"
{
    Extensible = true;

    value(0; None)
    {
        Caption = ' ';
    }
    value(1; New)
    {
        Caption = 'New';
    }
    value(2; Change)
    {
        Caption = 'Change';
    }
    value(3; Cancel)
    {
        Caption = 'Cancel';
    }
}
