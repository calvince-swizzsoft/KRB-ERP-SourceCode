table 59082 "Instant Loan Block History"
{
    Caption = 'Instant Loan Block History';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Member No."; Code[20]) { TableRelation = Customer."No."; }
        field(3; Blocked; Boolean) { }
        field(4; "Changed By"; Code[50]) { }
        field(5; "Changed At"; DateTime) { }
        field(6; "Expires On"; Date) { }
        field(7; "Months in Default"; Integer) { }
        field(8; "Block Duration (Months)"; Integer) { }
        field(9; "Block Duration (Days)"; Integer) { }
        field(10; "Arrears Days at Block"; Integer) { }
        field(11; "Arrears Loan No."; Code[30]) { }
        field(12; "Arrears Loan Description"; Text[100]) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(MemberHistory; "Member No.", "Entry No.") { }
    }
}
