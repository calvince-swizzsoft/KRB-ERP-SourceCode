page 59081 "Instant Loan Member Blocks"
{
    Caption = 'Instant Loan Member Blocks';
    PageType = List;
    SourceTable = "Instant Loan Block Buffer";
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Members)
            {
                field("Member No."; Rec."Member No.") { ApplicationArea = All; Editable = false; }
                field("Member Name"; Rec."Member Name") { ApplicationArea = All; Editable = false; }
                field("Months in Arrears"; Rec."Months in Arrears")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of complete 30-day periods in arrears on the most overdue active loan.';
                }
                field("Days in Arrears"; Rec."Days in Arrears")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the remaining days in arrears after complete 30-day periods on the most overdue active loan.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Select and enter how many days to block instant loan applications through the portal. Clear to unblock immediately.';
                    trigger OnValidate()
                    var
                        BlockMgt: Codeunit "Instant Loan Block Mgt.";
                        MemberBlock: Record "Instant Loan Member Block";
                        BlockDuration: Page "Instant Loan Block Duration";
                    begin
                        if Rec.Blocked then begin
                            if BlockDuration.RunModal() <> Action::OK then begin
                                Rec.Blocked := xRec.Blocked;
                                exit;
                            end;
                            BlockMgt.BlockForDays(Rec."Member No.", xRec.Blocked, BlockDuration.GetDays());
                        end else
                            BlockMgt.SetBlocked(Rec."Member No.", false, xRec.Blocked);
                        if MemberBlock.Get(Rec."Member No.") then
                            CopyBlockDetails(MemberBlock, Today());
                    end;
                }
                field("Expires On"; Rec."Expires On")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the date the member can apply for instant loans again. A blank date on a blocked member means the block has no expiration.';
                }
                field("Changed By"; Rec."Changed By") { ApplicationArea = All; Editable = false; }
                field("Changed At"; Rec."Changed At") { ApplicationArea = All; Editable = false; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(RefreshMembers)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;
                trigger OnAction()
                begin
                    LoadMembers();
                    CurrPage.Update(false);
                end;
            }
            action(BlockHistory)
            {
                Caption = 'Block History';
                ApplicationArea = All;
                Image = History;
                RunObject = page "Instant Loan Block History";
                RunPageLink = "Member No." = field("Member No.");
            }
        }
    }
    trigger OnOpenPage()
    begin
        LoadMembers();
    end;

    local procedure LoadMembers()
    var
        Loan: Record "Loans Register";
        MemberBlock: Record "Instant Loan Member Block";
        BlockMgt: Codeunit "Instant Loan Block Mgt.";
        AsOfDate: Date;
    begin
        AsOfDate := Today();
        Rec.Reset();
        Rec.DeleteAll();
        BlockMgt.FilterActiveArrears(Loan);
        Loan.SetLoadFields("Client Code", "No of Days in Arrears");
        if Loan.FindSet() then
            repeat
                if GetOrAddMember(Loan."Client Code") then
                    if Loan."No of Days in Arrears" > Rec."Months in Arrears" * 30 + Rec."Days in Arrears" then begin
                        Rec."Months in Arrears" := Loan."No of Days in Arrears" div 30;
                        Rec."Days in Arrears" := Loan."No of Days in Arrears" mod 30;
                        Rec.Modify();
                    end;
            until Loan.Next() = 0;

        MemberBlock.SetRange(Blocked, true);
        MemberBlock.SetFilter("Expires On", '%1|>%2', 0D, AsOfDate);
        if MemberBlock.FindSet() then
            repeat
                if GetOrAddMember(MemberBlock."Member No.") then begin
                    CopyBlockDetails(MemberBlock, AsOfDate);
                    Rec.Modify();
                end;
            until MemberBlock.Next() = 0;
        if Rec.FindFirst() then;
    end;

    local procedure GetOrAddMember(MemberNo: Code[20]): Boolean
    var
        Member: Record Customer;
    begin
        if Rec.Get(MemberNo) then
            exit(true);
        if not Member.Get(MemberNo) then
            exit(false);
        if (Member."Customer Type" <> Member."Customer Type"::Member) or (Member."Customer Posting Group" <> 'MEMBER') then
            exit(false);
        Rec.Init();
        Rec."Member No." := MemberNo;
        Rec."Member Name" := Member.Name;
        Rec.Insert();
        exit(true);
    end;

    local procedure CopyBlockDetails(MemberBlock: Record "Instant Loan Member Block"; AsOfDate: Date)
    begin
        Rec.Blocked := MemberBlock.IsActive(AsOfDate);
        Rec."Expires On" := MemberBlock."Expires On";
        Rec."Changed By" := MemberBlock."Changed By";
        Rec."Changed At" := MemberBlock."Changed At";
    end;
}
