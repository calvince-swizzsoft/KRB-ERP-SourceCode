codeunit 59081 "Instant Loan Block Mgt."
{
    Permissions = tabledata "Loans Register" = R;

    procedure IsBlocked(MemberNo: Code[60]; ProductCode: Text): Boolean
    var
        MemberBlock: Record "Instant Loan Member Block";
    begin
        exit(GetActiveBlock(MemberNo, ProductCode, MemberBlock));
    end;

    local procedure GetActiveBlock(MemberNo: Code[60]; ProductCode: Text; var MemberBlock: Record "Instant Loan Member Block"): Boolean
    begin
        // These are the instant products used by the existing instant loan pages.
        if not (UpperCase(ProductCode) in ['LT006', 'LT007']) then
            exit(false);
        if StrLen(MemberNo) > MaxStrLen(MemberBlock."Member No.") then
            exit(false);
        if MemberBlock.Get(MemberNo) then
            exit(MemberBlock.IsActive(Today()));
        exit(false);
    end;

    procedure CheckAvailable(MemberNo: Code[60]; ProductCode: Text)
    begin
        if IsBlocked(MemberNo, ProductCode) then
            Error(UnavailableMessage());
    end;

    procedure UnavailableMessage(): Text
    begin
        exit(LoanUnavailableLbl);
    end;

    procedure GetApplicationBlockMessage(MemberNo: Code[60]; ProductCode: Text): Text
    var
        MemberBlock: Record "Instant Loan Member Block";
        MostOverdueLoan: Record "Loans Register";
        LoanNo: Code[30];
        LoanDescription: Text[100];
        ArrearsDays: Integer;
        LoanReference: Text;
    begin
        if not GetActiveBlock(MemberNo, ProductCode, MemberBlock) then
            exit('');
        if MemberBlock."Block Duration (Days)" > 0 then begin
            LoanNo := MemberBlock."Arrears Loan No.";
            LoanDescription := MemberBlock."Arrears Loan Description";
            ArrearsDays := MemberBlock."Arrears Days at Block";
            if LoanNo = '' then
                if FindMostOverdueLoan(MemberBlock."Member No.", MostOverdueLoan) then begin
                    LoanNo := MostOverdueLoan."Loan  No.";
                    LoanDescription := MostOverdueLoan."Loan Product Type Name";
                    ArrearsDays := MostOverdueLoan."No of Days in Arrears";
                end;
            if LoanNo <> '' then
                if LoanDescription <> '' then
                    LoanReference := StrSubstNo(LoanDescriptionAndNoLbl, LoanDescription, LoanNo)
                else
                    LoanReference := StrSubstNo(LoanNoLbl, LoanNo);
            exit(StrSubstNo(LoanBlockedLbl, LoanReference, FormatDays(ArrearsDays),
                FormatDays(MemberBlock."Block Duration (Days)")));
        end;
        if (MemberBlock."Months in Default" > 0) and (MemberBlock."Block Duration (Months)" > 0) then
            exit(StrSubstNo(ApplicationBlockedLbl, FormatMonths(MemberBlock."Months in Default"), FormatMonths(MemberBlock."Block Duration (Months)")));
        exit(StrSubstNo(ApplicationUnavailableLbl, UnavailableMessage()));
    end;

    local procedure FormatMonths(Months: Integer): Text
    begin
        if Months = 1 then
            exit(OneMonthLbl);
        exit(StrSubstNo(MonthsLbl, Months));
    end;

    local procedure FormatDays(Days: Integer): Text
    begin
        if Days = 1 then
            exit(OneDayLbl);
        exit(StrSubstNo(DaysLbl, Days));
    end;

    procedure FilterActiveArrears(var Loan: Record "Loans Register")
    begin
        Loan.SetRange(Posted, true);
        Loan.SetRange(Reversed, false);
        Loan.SetFilter("Outstanding Balance", '>0');
        Loan.SetFilter("Amount in Arrears", '>0');
        Loan.SetFilter("No of Days in Arrears", '>0');
    end;

    procedure BlockForDays(MemberNo: Code[20]; ExpectedBlocked: Boolean; Days: Integer)
    var
        MostOverdueLoan: Record "Loans Register";
        StartDate: Date;
    begin
        if Days < 1 then
            Error('Enter a block duration of at least one day.');
        if not FindMostOverdueLoan(MemberNo, MostOverdueLoan) then
            Error('This member has no active loan arrears. Refresh the list and try again.');
        StartDate := Today();
        SetBlock(MemberNo, true, ExpectedBlocked, Days, MostOverdueLoan, StartDate + Days, StartDate);
    end;

    local procedure FindMostOverdueLoan(MemberNo: Code[20]; var MostOverdueLoan: Record "Loans Register"): Boolean
    var
        Loan: Record "Loans Register";
    begin
        Clear(MostOverdueLoan);
        FilterActiveArrears(Loan);
        Loan.SetRange("Client Code", MemberNo);
        Loan.SetLoadFields("No of Days in Arrears", "Loan Product Type Name");
        if not Loan.FindSet() then
            exit(false);
        repeat
            if Loan."No of Days in Arrears" > MostOverdueLoan."No of Days in Arrears" then
                MostOverdueLoan := Loan;
        until Loan.Next() = 0;
        exit(true);
    end;

    procedure SetBlocked(MemberNo: Code[20]; NewBlocked: Boolean; ExpectedBlocked: Boolean)
    var
        Loan: Record "Loans Register";
    begin
        SetBlock(MemberNo, NewBlocked, ExpectedBlocked, 0, Loan, 0D, Today());
    end;

    local procedure SetBlock(MemberNo: Code[20]; NewBlocked: Boolean; ExpectedBlocked: Boolean; Days: Integer; ArrearsLoan: Record "Loans Register"; ExpiresOn: Date; AsOfDate: Date)
    var
        MemberBlock: Record "Instant Loan Member Block";
        Member: Record Customer;
    begin
        Member.Get(MemberNo);
        MemberBlock.LockTable();
        if MemberBlock.Get(MemberNo) then begin
            if MemberBlock.IsActive(AsOfDate) <> ExpectedBlocked then
                Error('The block status has changed. Refresh the list and try again.');
            if (MemberBlock.Blocked = NewBlocked) and (MemberBlock."Expires On" = ExpiresOn) and
               (MemberBlock."Block Duration (Days)" = Days) and (MemberBlock."Arrears Days at Block" = ArrearsLoan."No of Days in Arrears") and
               (MemberBlock."Arrears Loan No." = ArrearsLoan."Loan  No.") and (MemberBlock."Arrears Loan Description" = ArrearsLoan."Loan Product Type Name") then
                exit;
            MemberBlock.Blocked := NewBlocked;
            MemberBlock."Expires On" := ExpiresOn;
            MemberBlock."Block Duration (Months)" := 0;
            MemberBlock."Months in Default" := 0;
            MemberBlock."Block Duration (Days)" := Days;
            MemberBlock."Arrears Days at Block" := ArrearsLoan."No of Days in Arrears";
            MemberBlock."Arrears Loan No." := ArrearsLoan."Loan  No.";
            MemberBlock."Arrears Loan Description" := ArrearsLoan."Loan Product Type Name";
            MemberBlock.Modify(true);
        end else begin
            if ExpectedBlocked then
                Error('The block status has changed. Refresh the list and try again.');
            if not NewBlocked then
                exit;
            MemberBlock.Init();
            MemberBlock."Member No." := MemberNo;
            MemberBlock.Blocked := NewBlocked;
            MemberBlock."Expires On" := ExpiresOn;
            MemberBlock."Block Duration (Months)" := 0;
            MemberBlock."Months in Default" := 0;
            MemberBlock."Block Duration (Days)" := Days;
            MemberBlock."Arrears Days at Block" := ArrearsLoan."No of Days in Arrears";
            MemberBlock."Arrears Loan No." := ArrearsLoan."Loan  No.";
            MemberBlock."Arrears Loan Description" := ArrearsLoan."Loan Product Type Name";
            MemberBlock.Insert(true);
        end;
    end;

    var
        ApplicationBlockedLbl: Label 'Failed: You have been in default for %1 and are blocked from applying for instant loans for %2.', Comment = '%1 = time in default, %2 = total block duration';
        ApplicationUnavailableLbl: Label 'Failed: %1', Comment = '%1 = loan unavailable message';
        OneMonthLbl: Label '1 month';
        MonthsLbl: Label '%1 months', Comment = '%1 = number of months';
        LoanBlockedLbl: Label 'Failed: Your loan%1 has run into default for %2. You are blocked from applying for instant loans for %3.', Comment = '%1 = optional loan description and number, %2 = time in default, %3 = total block duration';
        LoanDescriptionAndNoLbl: Label ' %1 (%2)', Comment = '%1 = loan description, %2 = loan number';
        LoanNoLbl: Label ' (%1)', Comment = '%1 = loan number';
        OneDayLbl: Label '1 day';
        DaysLbl: Label '%1 days', Comment = '%1 = number of days';
        LoanUnavailableLbl: Label 'Loan not available', Locked = true;
}
