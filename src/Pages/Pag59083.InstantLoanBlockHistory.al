page 59083 "Instant Loan Block History"
{
    Caption = 'Instant Loan Block History';
    PageType = List;
    SourceTable = "Instant Loan Block History";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    ApplicationArea = All;
    UsageCategory = History;
    layout
    {
        area(Content)
        {
            repeater(Changes)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Member No."; Rec."Member No.") { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
                field("Months in Default"; Rec."Months in Default") { ApplicationArea = All; }
                field("Block Duration (Months)"; Rec."Block Duration (Months)") { ApplicationArea = All; }
                field("Block Duration (Days)"; Rec."Block Duration (Days)") { ApplicationArea = All; }
                field("Arrears Loan No."; Rec."Arrears Loan No.") { ApplicationArea = All; }
                field("Arrears Loan Description"; Rec."Arrears Loan Description") { ApplicationArea = All; }
                field("Arrears Days at Block"; Rec."Arrears Days at Block") { ApplicationArea = All; }
                field("Expires On"; Rec."Expires On") { ApplicationArea = All; }
                field("Changed By"; Rec."Changed By") { ApplicationArea = All; }
                field("Changed At"; Rec."Changed At") { ApplicationArea = All; }
            }
        }
    }
}
