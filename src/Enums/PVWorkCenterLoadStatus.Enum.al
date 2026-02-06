/// <summary>
/// Status der Work Center Auslastung.
/// </summary>
enum 50101 "PV Work Center Load Status"
{
    Extensible = true;
    Caption = 'Work Center Load Status';

    value(0; OK)
    {
        Caption = 'OK';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Overload)
    {
        Caption = 'Overload';
    }
}
