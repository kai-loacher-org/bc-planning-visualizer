/// <summary>
/// Typ einer Kante (Beziehung) im Abhängigkeitsgraph.
/// </summary>
enum 50101 "Dependency Edge Type"
{
    Extensible = true;

    value(0; Component)
    {
        Caption = 'Component';
    }
    value(1; Reservation)
    {
        Caption = 'Reservation';
    }
    value(2; OrderTracking)
    {
        Caption = 'Order Tracking';
    }
    value(3; BOMLevel)
    {
        Caption = 'BOM Level';
    }
}
