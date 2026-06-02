unit TaskForm;

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls,
  Dialogs,
  AppCoreTaskItem,
  AppCoreTaskRepository,
  AppCoreTaskService;

type
  TFrmTasks = class(TForm)
    PnlTop: TPanel;
    EdtTitle: TEdit;
    BtnAdd: TButton;
    EdtSearch: TEdit;
    BtnSearch: TButton;
    LstTasks: TListBox;
    PnlBottom: TPanel;
    BtnComplete: TButton;
    BtnDelete: TButton;
    BtnRefresh: TButton;
    procedure FormCreate(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnCompleteClick(Sender: TObject);
    procedure BtnDeleteClick(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnSearchClick(Sender: TObject);
  private
    FService: ITaskService;
    FCurrentTasks: TTaskItemArray;

    procedure RefreshList(const ATasks: TTaskItemArray);
    function SelectedTask: TTaskItem;
  end;

implementation

{$R *.dfm}

uses
  AppCoreClock;

procedure TFrmTasks.FormCreate(Sender: TObject);
begin
  FService := TTaskService.Create(TInMemoryTaskRepository.Create, TSystemClock.Create);
  RefreshList(FService.ListTasks);
end;

procedure TFrmTasks.BtnAddClick(Sender: TObject);
begin
  try
    FService.CreateTask(EdtTitle.Text);
    EdtTitle.Clear;
    RefreshList(FService.ListTasks);
  except
    on E: ETaskValidationError do
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
  end;
end;

procedure TFrmTasks.BtnCompleteClick(Sender: TObject);
begin
  if LstTasks.ItemIndex < 0 then
    Exit;

  FService.CompleteTask(SelectedTask.Id);
  RefreshList(FService.ListTasks);
end;

procedure TFrmTasks.BtnDeleteClick(Sender: TObject);
begin
  if LstTasks.ItemIndex < 0 then
    Exit;

  FService.DeleteTask(SelectedTask.Id);
  RefreshList(FService.ListTasks);
end;

procedure TFrmTasks.BtnRefreshClick(Sender: TObject);
begin
  EdtSearch.Clear;
  RefreshList(FService.ListTasks);
end;

procedure TFrmTasks.BtnSearchClick(Sender: TObject);
begin
  RefreshList(FService.SearchTasks(EdtSearch.Text));
end;

procedure TFrmTasks.RefreshList(const ATasks: TTaskItemArray);
var
  I: Integer;
  LPrefix: string;
begin
  FCurrentTasks := ATasks;
  LstTasks.Items.BeginUpdate;
  try
    LstTasks.Clear;
    for I := 0 to Length(FCurrentTasks) - 1 do
    begin
      if FCurrentTasks[I].IsCompleted then
        LPrefix := '[x] '
      else
        LPrefix := '[ ] ';

      LstTasks.Items.Add(LPrefix + FCurrentTasks[I].Title);
    end;
  finally
    LstTasks.Items.EndUpdate;
  end;
end;

function TFrmTasks.SelectedTask: TTaskItem;
begin
  Result := FCurrentTasks[LstTasks.ItemIndex];
end;

end.
