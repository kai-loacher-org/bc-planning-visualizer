/// <summary>
/// Status eines Knotens (für visuelle Hervorhebung).
/// </summary>
enum 50103 "Dependency Node Status"
{
    Extensible = true;

    value(0; OK)
    {
        Caption = 'OK';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Critical)
    {
        Caption = 'Critical';
    }
    value(3; Completed)
    {
        Caption = 'Completed';
    }
}
