page 59086 "Instant Loan Block Duration"
{
    Caption = 'Block Instant Loans';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(Days; Days)
            {
                ApplicationArea = All;
                Caption = 'Block Duration (Days)';
                MinValue = 1;
                ToolTip = 'Specifies how many calendar days the block lasts, starting today.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction = Action::OK) and (Days < 1) then
            Error('Enter a block duration of at least one day.');
        exit(true);
    end;

    procedure GetDays(): Integer
    begin
        exit(Days);
    end;

    var
        Days: Integer;
}
