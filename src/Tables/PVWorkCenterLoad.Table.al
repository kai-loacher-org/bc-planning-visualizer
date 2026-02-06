/// <summary>
/// Temporäre Tabelle für Work Center Auslastung.
/// Zeigt Kapazität vs. geplante Last pro Periode.
/// </summary>
table 50102 "PV Work Center Load"
{
    Caption = 'Work Center Load';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
        }
        field(3; "Work Center Name"; Text[100])
        {
            Caption = 'Work Center Name';
        }
        field(10; "Period Start"; Date)
        {
            Caption = 'Period Start';
        }
        field(11; "Period End"; Date)
        {
            Caption = 'Period End';
        }
        field(20; "Capacity (Hours)"; Decimal)
        {
            Caption = 'Capacity (Hours)';
            DecimalPlaces = 0 : 2;
        }
        field(21; "Load (Hours)"; Decimal)
        {
            Caption = 'Load (Hours)';
            DecimalPlaces = 0 : 2;
        }
        field(22; "Load %"; Decimal)
        {
            Caption = 'Load %';
            DecimalPlaces = 0 : 1;
        }
        field(30; Status; Enum "PV Work Center Load Status")
        {
            Caption = 'Status';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(WorkCenterPeriod; "Work Center No.", "Period Start")
        {
        }
    }

    procedure CalculateLoadPercent()
    begin
        if "Capacity (Hours)" > 0 then
            "Load %" := Round("Load (Hours)" / "Capacity (Hours)" * 100, 0.1)
        else
            "Load %" := 0;

        if "Load %" > 100 then
            Status := Status::Overload
        else
            if "Load %" > 80 then
                Status := Status::Warning
            else
                Status := Status::OK;
    end;
}
