/// <summary>
/// Part-Page für die Work Center Auslastung.
/// Zeigt die Kapazitätsauslastung pro Work Center und Woche.
/// </summary>
page 50101 "PV Work Center Load Part"
{
    PageType = ListPart;
    ApplicationArea = Manufacturing;
    Caption = 'Work Center Load';
    SourceTable = "PV Work Center Load";
    SourceTableTemporary = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Load)
            {
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Work Center Number.';
                }
                field("Work Center Name"; Rec."Work Center Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Work Center Name.';
                }
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Start of the period.';
                }
                field("Period End"; Rec."Period End")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'End of the period.';
                }
                field("Capacity (Hours)"; Rec."Capacity (Hours)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Available capacity in hours.';
                }
                field("Load (Hours)"; Rec."Load (Hours)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Planned load in hours.';
                }
                field("Load %"; Rec."Load %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Load as percentage of capacity.';
                    StyleExpr = LoadStyle;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Status: OK, Warning (>80%), Overload (>100%).';
                    StyleExpr = LoadStyle;
                }
            }
        }
    }

    var
        LoadStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Overload:
                LoadStyle := 'Unfavorable';
            Rec.Status::Warning:
                LoadStyle := 'Attention';
            else
                LoadStyle := 'Favorable';
        end;
    end;

    procedure SetData(var TempWorkCenterLoad: Record "PV Work Center Load" temporary)
    begin
        Rec.Copy(TempWorkCenterLoad, true);
        CurrPage.Update(false);
    end;
}
