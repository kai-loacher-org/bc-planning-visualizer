/// <summary>
/// Status eines Gantt-Tasks (für visuelle Hervorhebung).
/// </summary>
enum 50100 "PV Gantt Task Status"
{
    Extensible = true;
    Caption = 'Gantt Task Status';

    value(0; Planned)
    {
        Caption = 'Planned';
    }
    value(1; InProgress)
    {
        Caption = 'In Progress';
    }
    value(2; Finished)
    {
        Caption = 'Finished';
    }
    value(3; Delayed)
    {
        Caption = 'Delayed';
    }
}
