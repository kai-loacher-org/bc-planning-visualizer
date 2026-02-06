/// <summary>
/// FactBox das die Abhängigkeiten für einen Task zeigt.
/// Welche anderen FAs liefern Komponenten für diesen Task?
/// </summary>
page 50102 "PV Dependencies FactBox"
{
    PageType = ListPart;
    ApplicationArea = Manufacturing;
    Caption = 'Dependencies';
    SourceTable = "PV Gantt Dependency";
    SourceTableTemporary = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Dependencies)
            {
                field("From Task ID"; Rec."From Task ID")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Supplying Task';
                    ToolTip = 'The task that supplies a component.';
                }
                field("Component Item No."; Rec."Component Item No.")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Component';
                    ToolTip = 'The item that is supplied.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Quantity needed.';
                }
            }
        }
    }
}
