/// <summary>
/// Codeunit zum Exportieren der Planungsdaten als JSON für das Frontend.
/// </summary>
codeunit 50101 "PV JSON Export"
{
    /// <summary>
    /// Exportiert alle Daten als JSON für das Gantt Control Add-In.
    /// </summary>
    procedure ExportToJson(
        var TempGanttTask: Record "PV Gantt Task" temporary;
        var TempGanttDependency: Record "PV Gantt Dependency" temporary;
        var TempWorkCenterLoad: Record "PV Work Center Load" temporary): Text
    var
        JsonObj: JsonObject;
        TasksArray: JsonArray;
        DepsArray: JsonArray;
        LoadArray: JsonArray;
    begin
        // Tasks
        TempGanttTask.Reset();
        if TempGanttTask.FindSet() then
            repeat
                TasksArray.Add(TaskToJson(TempGanttTask));
            until TempGanttTask.Next() = 0;
        JsonObj.Add('tasks', TasksArray);

        // Dependencies
        TempGanttDependency.Reset();
        if TempGanttDependency.FindSet() then
            repeat
                DepsArray.Add(DependencyToJson(TempGanttDependency));
            until TempGanttDependency.Next() = 0;
        JsonObj.Add('dependencies', DepsArray);

        // Work Center Load
        TempWorkCenterLoad.Reset();
        if TempWorkCenterLoad.FindSet() then
            repeat
                LoadArray.Add(WorkCenterLoadToJson(TempWorkCenterLoad));
            until TempWorkCenterLoad.Next() = 0;
        JsonObj.Add('workCenterLoad', LoadArray);

        exit(Format(JsonObj));
    end;

    local procedure TaskToJson(TempGanttTask: Record "PV Gantt Task" temporary): JsonObject
    var
        JsonObj: JsonObject;
    begin
        JsonObj.Add('id', TempGanttTask."Task ID");
        JsonObj.Add('name', TempGanttTask."Task Name");
        JsonObj.Add('prodOrderNo', TempGanttTask."Prod. Order No.");
        JsonObj.Add('operationNo', TempGanttTask."Operation No.");
        JsonObj.Add('itemNo', TempGanttTask."Item No.");
        JsonObj.Add('itemDescription', TempGanttTask."Item Description");
        JsonObj.Add('workCenterNo', TempGanttTask."Work Center No.");
        JsonObj.Add('workCenterName', TempGanttTask."Work Center Name");
        JsonObj.Add('start', FormatDateTime(TempGanttTask."Starting Date-Time"));
        JsonObj.Add('end', FormatDateTime(TempGanttTask."Ending Date-Time"));
        JsonObj.Add('durationHours', TempGanttTask."Duration (Hours)");
        JsonObj.Add('progress', TempGanttTask."Progress %");
        JsonObj.Add('status', Format(TempGanttTask.Status));
        JsonObj.Add('isCriticalPath', TempGanttTask."Is Critical Path");
        JsonObj.Add('quantity', TempGanttTask.Quantity);
        exit(JsonObj);
    end;

    local procedure DependencyToJson(TempGanttDependency: Record "PV Gantt Dependency" temporary): JsonObject
    var
        JsonObj: JsonObject;
    begin
        JsonObj.Add('from', TempGanttDependency."From Task ID");
        JsonObj.Add('to', TempGanttDependency."To Task ID");
        JsonObj.Add('componentItemNo', TempGanttDependency."Component Item No.");
        JsonObj.Add('quantity', TempGanttDependency.Quantity);
        exit(JsonObj);
    end;

    local procedure WorkCenterLoadToJson(TempWorkCenterLoad: Record "PV Work Center Load" temporary): JsonObject
    var
        JsonObj: JsonObject;
    begin
        JsonObj.Add('workCenterNo', TempWorkCenterLoad."Work Center No.");
        JsonObj.Add('workCenterName', TempWorkCenterLoad."Work Center Name");
        JsonObj.Add('periodStart', Format(TempWorkCenterLoad."Period Start", 0, '<Year4>-<Month,2>-<Day,2>'));
        JsonObj.Add('periodEnd', Format(TempWorkCenterLoad."Period End", 0, '<Year4>-<Month,2>-<Day,2>'));
        JsonObj.Add('capacityHours', TempWorkCenterLoad."Capacity (Hours)");
        JsonObj.Add('loadHours', TempWorkCenterLoad."Load (Hours)");
        JsonObj.Add('loadPercent', TempWorkCenterLoad."Load %");
        JsonObj.Add('status', Format(TempWorkCenterLoad.Status));
        exit(JsonObj);
    end;

    local procedure FormatDateTime(Value: DateTime): Text
    begin
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;
}
