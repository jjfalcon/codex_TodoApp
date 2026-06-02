unit AppCoreTaskItem;

interface

type
  TTaskStatus = (tsPending, tsCompleted);

  TTaskItem = class
  private
    FId: string;
    FTitle: string;
    FCreatedAt: TDateTime;
    FCompletedAt: TDateTime;
    FStatus: TTaskStatus;
  public
    constructor Create(const AId, ATitle: string; const ACreatedAt: TDateTime);
    function IsCompleted: Boolean;

    property Id: string read FId;
    property Title: string read FTitle write FTitle;
    property CreatedAt: TDateTime read FCreatedAt;
    property CompletedAt: TDateTime read FCompletedAt write FCompletedAt;
    property Status: TTaskStatus read FStatus write FStatus;
  end;

  TTaskItemArray = array of TTaskItem;

implementation

constructor TTaskItem.Create(const AId, ATitle: string; const ACreatedAt: TDateTime);
begin
  inherited Create;
  FId := AId;
  FTitle := ATitle;
  FCreatedAt := ACreatedAt;
  FCompletedAt := 0;
  FStatus := tsPending;
end;

function TTaskItem.IsCompleted: Boolean;
begin
  Result := FStatus = tsCompleted;
end;

end.
