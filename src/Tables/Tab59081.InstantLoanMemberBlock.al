table 59081 "Instant Loan Member Block"
{
    Caption = 'Instant Loan Member Block';
    DataClassification = CustomerContent;
    Permissions = tabledata "Instant Loan Block History" = I;

    fields
    {
        field(1; "Member No."; Code[20])
        {
            TableRelation = Customer."No.";
        }
        field(2; Blocked; Boolean) { }
        field(3; "Changed By"; Code[50]) { Editable = false; }
        field(4; "Changed At"; DateTime) { Editable = false; }
        field(5; "Expires On"; Date) { Editable = false; }
        field(6; "Months in Default"; Integer) { Editable = false; }
        field(7; "Block Duration (Months)"; Integer) { Editable = false; }
        field(8; "Block Duration (Days)"; Integer) { Editable = false; }
        field(9; "Arrears Days at Block"; Integer) { Editable = false; }
        field(10; "Arrears Loan No."; Code[30]) { Editable = false; }
        field(11; "Arrears Loan Description"; Text[100]) { Editable = false; }
    }
    keys
    {
        key(PK; "Member No.") { Clustered = true; }
        key(BlockedMembers; Blocked) { }
    }

    trigger OnInsert()
    var
        Member: Record Customer;
    begin
        TestField("Member No.");
        Member.Get("Member No.");
        RecordChange();
    end;

    trigger OnModify()
    begin
        if (Blocked <> xRec.Blocked) or ("Expires On" <> xRec."Expires On") or
           ("Months in Default" <> xRec."Months in Default") or ("Block Duration (Months)" <> xRec."Block Duration (Months)") or
           ("Block Duration (Days)" <> xRec."Block Duration (Days)") or ("Arrears Days at Block" <> xRec."Arrears Days at Block") or
           ("Arrears Loan No." <> xRec."Arrears Loan No.") or ("Arrears Loan Description" <> xRec."Arrears Loan Description") then
            RecordChange();
    end;

    trigger OnDelete()
    begin
        Error('Uncheck Blocked to unblock the member. Block records cannot be deleted.');
    end;

    trigger OnRename()
    begin
        Error('The member number cannot be changed.');
    end;

    procedure IsActive(AsOfDate: Date): Boolean
    begin
        exit(Blocked and (("Expires On" = 0D) or ("Expires On" > AsOfDate)));
    end;

    local procedure RecordChange()
    var
        History: Record "Instant Loan Block History";
    begin
        "Changed By" := CopyStr(UserId(), 1, MaxStrLen("Changed By"));
        "Changed At" := CurrentDateTime();
        History.Init();
        History."Member No." := "Member No.";
        History.Blocked := Blocked;
        History."Expires On" := "Expires On";
        History."Months in Default" := "Months in Default";
        History."Block Duration (Months)" := "Block Duration (Months)";
        History."Block Duration (Days)" := "Block Duration (Days)";
        History."Arrears Days at Block" := "Arrears Days at Block";
        History."Arrears Loan No." := "Arrears Loan No.";
        History."Arrears Loan Description" := "Arrears Loan Description";
        History."Changed By" := "Changed By";
        History."Changed At" := "Changed At";
        History.Insert(true);
    end;
}
