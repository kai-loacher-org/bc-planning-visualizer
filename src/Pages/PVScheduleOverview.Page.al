/// <summary>
/// Übersichtsseite für die Fertigungsplanung.
/// Zeigt alle Tasks, Abhängigkeiten und Work Center Auslastung.
/// Später wird hier das Gantt Control Add-In eingebunden.
/// </summary>
page 50100 "PV Schedule Overview"
{
    PageType = Worksheet;
    ApplicationArea = Manufacturing;
    UsageCategory = Tasks;
    Caption = 'Production Schedule Visualizer';
    SourceTable = "PV Gantt Task";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filter';

                field(FromDateFilter; FromDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'From Date';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
                field(ToDateFilter; ToDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'To Date';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
            }

            repeater(Tasks)
            {
                Caption = 'Tasks';

                field("Task ID"; Rec."Task ID")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Unique identifier for this task.';
                }
                field("Task Name"; Rec."Task Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Name of the task (Item + Operation).';
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Production Order Number.';
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Operation Number from the routing.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Item being produced.';
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Work Center where this operation runs.';
                }
                field("Work Center Name"; Rec."Work Center Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Name of the Work Center.';
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'When this operation starts.';
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'When this operation ends.';
                }
                field("Duration (Hours)"; Rec."Duration (Hours)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Duration in hours.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Current status of the task.';
                    StyleExpr = StatusStyle;
                }
                field("Progress %"; Rec."Progress %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Completion percentage.';
                }
            }

            part(WorkCenterLoad; "PV Work Center Load Part")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Center Load';
            }
        }

        area(FactBoxes)
        {
            part(Dependencies; "PV Dependencies FactBox")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "To Task ID" = field("Task ID");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Reload the schedule data.';

                trigger OnAction()
                begin
                    RefreshData();
                end;
            }
            action(ExportJson)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Export JSON';
                Image = Export;
                ToolTip = 'Export the schedule as JSON for external visualization.';

                trigger OnAction()
                var
                    JsonExport: Codeunit "PV JSON Export";
                    JsonText: Text;
                begin
                    JsonText := JsonExport.ExportToJson(Rec, TempGanttDependency, TempWorkCenterLoad);
                    Message('JSON Length: %1 characters', StrLen(JsonText));
                end;
            }
            action(OpenProdOrder)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Open Production Order';
                Image = Production;
                ToolTip = 'Open the related Production Order.';

                trigger OnAction()
                var
                    ProdOrder: Record "Production Order";
                begin
                    if ProdOrder.Get(Rec."Prod. Order Status", Rec."Prod. Order No.") then
                        Page.Run(Page::"Released Production Order", ProdOrder);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Refresh_Promoted; Refresh) { }
                actionref(ExportJson_Promoted; ExportJson) { }
                actionref(OpenProdOrder_Promoted; OpenProdOrder) { }
            }
        }
    }

    var
        TempGanttDependency: Record "PV Gantt Dependency" temporary;
        TempWorkCenterLoad: Record "PV Work Center Load" temporary;
        FromDate: Date;
        ToDate: Date;
        StatusStyle: Text;

    trigger OnOpenPage()
    begin
        FromDate := Today;
        ToDate := CalcDate('<+4W>', Today);
        RefreshData();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    local procedure RefreshData()
    var
        ScheduleBuilder: Codeunit "PV Schedule Builder";
    begin
        ScheduleBuilder.BuildSchedule(FromDate, ToDate, Rec, TempGanttDependency, TempWorkCenterLoad);
        CurrPage.WorkCenterLoad.Page.SetData(TempWorkCenterLoad);
        CurrPage.Update(false);
    end;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Delayed:
                StatusStyle := 'Unfavorable';
            Rec.Status::InProgress:
                StatusStyle := 'Attention';
            Rec.Status::Finished:
                StatusStyle := 'Favorable';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
