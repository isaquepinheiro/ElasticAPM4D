{ ******************************************************* }
{ }
{ Delphi Elastic Apm Agent }
{ }
{ Developed by Juliano Eichelberger }
{ }
{ ******************************************************* }
unit Apm4D.DataController;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Apm4D.Metadata, Apm4D.Span, Apm4D.Error, Apm4D.Transaction,
  Apm4D.Log;

type
  TDataController = class
  private const
    XndJsonSeparator = sLineBreak;
  private
    FMetadata: TMetadata;
    FTransaction: TTransaction;
    FSpanList: TObjectList<TSpan>;
    FErrorList: TObjectList<TError>;
    FLogList: TObjecTList<TAPMLog>;
    FOpenSpanStack: TList;
    FHeader: string;
    function ExtractTraceId: string;
    function ExtractParentID: string;
    function GetHeader: string;
    procedure SetHeader(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure ToQueue;

    function StartSpan(const AName, AType: string): TSpan;
    function SpanIsOpened: Boolean;
    function CurrentSpan: TSpan;
    procedure PauseAllOpenedSpans;
    procedure EndSpan;
    function HasErrors: boolean;

    property Transaction: TTransaction read FTransaction write FTransaction;
    property ErrorList: TObjectList<TError> read FErrorList;
    property LogList: TObjectList<TAPMLog> read FLogList;
    property Header: string read GetHeader write SetHeader;
  end;

implementation


uses
  System.DateUtils, StrUtils, Apm4D.Settings, Apm4D.QueueSingleton, Apm4D.Metricset, System.Threading;

constructor TDataController.Create;
begin
  FMetadata := TMetadata.Create;
  FTransaction := TTransaction.Create;
  FSpanList := TObjectList<TSpan>.Create;
  FOpenSpanStack := TList.Create;
  FErrorList := TObjectList<TError>.Create;
  FLogList := TObjectList<TAPMLog>.Create;
  FHeader := '';
end;

function TDataController.CurrentSpan: TSpan;
begin
  if not SpanIsOpened then
    exit(nil);

  Result := FOpenSpanStack.Items[Pred(FOpenSpanStack.Count)];
end;

procedure TDataController.PauseAllOpenedSpans;
var 
  I: Integer;
begin
  for I := 0 to FOpenSpanStack.Count - 1 do
    TSpan(FOpenSpanStack.Items[I]).Pause;
end;

destructor TDataController.Destroy;
begin
  FTransaction.Free;
  FMetadata.Free;
  FreeAndNil(FSpanList);
  FreeAndNil(FErrorList);
  FreeAndNil(FLogList);
  FOpenSpanStack.Free;
  inherited;
end;

function TDataController.SpanIsOpened: Boolean;
begin
  Result := FOpenSpanStack.Count > 0;
end;

function TDataController.StartSpan(const AName, AType: string): TSpan;
var
  TransactionPausedDuration: Int64;
begin
  if SpanIsOpened then
    Result := TSpan.Create(CurrentSpan.trace_id, CurrentSpan.transaction_id, CurrentSpan.id)
  else
    Result := TSpan.Create(FTransaction.trace_id, FTransaction.id, FTransaction.id);

  // Calcula a duração de pausa da Transaction até o momento
  TransactionPausedDuration := FTransaction.GetPausedDuration;
  if FTransaction.IsPaused then
    TransactionPausedDuration := TransactionPausedDuration + MilliSecondsBetween(now, FTransaction.GetPauseStartDate);

  Result.Start(AName, AType, TransactionPausedDuration);

  FSpanList.Add(Result);
  FOpenSpanStack.Add(Result);
  FTransaction.span_count.Inc;
end;

function TDataController.GetHeader: string;
begin
  Result := FHeader;
  if Result.IsEmpty then
  begin
    if SpanIsOpened then
      Result := Format('00-%s-%s-01', [FTransaction.trace_id, CurrentSpan.id])
    else
      Result := Format('00-%s-%s-01', [FTransaction.trace_id, FTransaction.id]);
  end
end;

function TDataController.HasErrors: boolean;
begin
  Result := (FErrorList.Count > 0);
end;

procedure TDataController.ToQueue;
var
  MetadataJson, TransactionJson, SpansJson, ErrorsJson, LogsJson: string;
  Tasks: array [0 .. 4] of ITask;
  Value: Widestring;
begin
  if not TApm4DSettings.IsActive then
    exit;

  // Serialize objects in parallel for better performance
  Tasks[0] := TTask.Create(
    procedure
    begin
      MetadataJson := FMetadata.ToJsonString;
    end);

  Tasks[1] := TTask.Create(
    procedure
    begin
      TransactionJson := FTransaction.ToJsonString;
    end);

  Tasks[2] := TTask.Create(
    procedure
    var
      Span: TSpan;
    begin
      SpansJson := '';
      if Assigned(FSpanList) then
        for Span in FSpanList do
          if Span <> nil then
            SpansJson := SpansJson + IfThen(not SpansJson.IsEmpty, XndJsonSeparator) + Span.ToJsonString;
    end);

  Tasks[3] := TTask.Create(
    procedure
    var
      Error: TError;
    begin
      ErrorsJson := '';
      if Assigned(FErrorList) then
        for Error in FErrorList do
          if Error <> nil then
            ErrorsJson := ErrorsJson + IfThen(not ErrorsJson.IsEmpty, XndJsonSeparator) + Error.ToJsonString;
    end);

  Tasks[4] := TTask.Create(
    procedure
    var
      LogEntry: TAPMLog;
    begin
      LogsJson := '';
      if Assigned(FLogList) then
        for LogEntry in FLogList do
          if LogEntry <> nil then
            LogsJson := LogsJson + IfThen(not LogsJson.IsEmpty, XndJsonSeparator) + LogEntry.ToJsonString;
    end);

  // Start all tasks
  for var Task in Tasks do
    Task.Start;

  // Wait for all serializations to complete
  TTask.WaitForAll(Tasks);

  // Add serialized content in correct order
  Value :=
    MetadataJson + XndJsonSeparator + TransactionJson +
    IfThen(not SpansJson.IsEmpty, XndJsonSeparator) + SpansJson +
    IfThen(not ErrorsJson.IsEmpty, XndJsonSeparator) + ErrorsJson +
    IfThen(not LogsJson.IsEmpty, XndJsonSeparator) + LogsJson;

  // Collect metrics (already parallel internally)
  TMetricSets.CollectAsync(
    procedure(AMetric: string)
    begin
      if not AMetric.IsEmpty then
        Value := Value + XndJsonSeparator + AMetric;
    end);

  TQueueSingleton.StackUp(Value, Header);
  FHeader := '';
end;

procedure TDataController.EndSpan;
begin
  CurrentSpan.ToEnd;
  FOpenSpanStack.Delete(Pred(FOpenSpanStack.Count));
  FTransaction.span_count.Dec;
end;

function TDataController.ExtractParentID: string;
begin
  Result := Copy(FHeader, 37, 16);
end;

function TDataController.ExtractTraceId: string;
begin
  Result := Copy(FHeader, 4, 32);
end;

procedure TDataController.SetHeader(const Value: string);
begin
  FHeader := Value;
  if not FHeader.IsEmpty then
  begin
    FTransaction.trace_id := ExtractTraceId;
    FTransaction.parent_id := ExtractParentID;
  end;
end;

end.
