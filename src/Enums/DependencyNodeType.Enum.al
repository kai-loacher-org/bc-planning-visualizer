/// <summary>
/// Typ eines Knotens im Abhängigkeitsgraph.
/// </summary>
enum 50100 "Dependency Node Type"
{
    Extensible = true;

    value(0; ReqLine)
    {
        Caption = 'Requisition Line';
    }
    value(1; ProdOrder)
    {
        Caption = 'Production Order';
    }
    value(2; PurchOrder)
    {
        Caption = 'Purchase Order';
    }
    value(3; SalesOrder)
    {
        Caption = 'Sales Order';
    }
    value(4; TransferOrder)
    {
        Caption = 'Transfer Order';
    }
    value(5; Component)
    {
        Caption = 'Component';
    }
    value(6; Reservation)
    {
        Caption = 'Reservation';
    }
    value(7; Item)
    {
        Caption = 'Item (Stock)';
    }
}
