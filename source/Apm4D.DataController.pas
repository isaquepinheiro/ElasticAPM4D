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
  Apm4D.Log, Apm4D.Share.Stacktrace;

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
    constructor Create(const AStackTracerFactory: TStackTracerFactory);
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

constructor TDataController.Create(const AStackTracerFactory: TStackTracerFactory);
begin
  FMetadata := TMetadata.Create;
  FTransaction := TTransaction.Create;
  FSpanList := TObjectList<TSpan>.Create;
  FOpenSpanStack := TList.Create;
  FErrorList := TObjectList<TError>.Create;
  FLogList := TObjectList<TAPMLog>.Create;
  FHeader := '';
  FTransaction.StackTracerFactory := AStackTracerFactory;
end;

function TDataController.CurrentSpan: TSpan;
begin
  if not SpanIsOpened then
    exit(nil);

  Result := FOpenSpanStack.Items[Pred(FOpenSpanStack.Count)];
end;

procedure TDataController.PauseAllOpenedSpans;
var
  LI: Integer;
begin
  for LI := 0 to FOpenSpanStack.Count - 1 do
    TSpan(FOpenSpanStack.Items[LI]).Pause;
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
  LTransactionPausedDuration: Int64;
begin
  if SpanIsOpened then
    Result := TSpan.Create(CurrentSpan.trace_id, CurrentSpan.transaction_id, CurrentSpan.id, FTransaction.StackTracerFactory)
  else
    Result := TSpan.Create(FTransaction.trace_id, FTransaction.id, FTransaction.id, FTransaction.StackTracerFactory);

  // Calcula a duração de pausa da Transaction até o momento
  LTransactionPausedDuration := FTransaction.GetPausedDuration;
  if FTransaction.IsPaused then
    LTransactionPausedDuration := LTransactionPausedDuration + MilliSecondsBetween(now, FTransaction.GetPauseStartDate);

  Result.Start(AName, AType, LTransactionPausedDuration);

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
  LMetadataJson, LTransactionJson, LSpansJson, LErrorsJson, LLogsJson: string;
  LTasks: array [0 .. 4] of ITask;
  LValue: Widestring;
begin
  if not TApm4DSettings.IsActive then
    exit;

  // Serialize objects in parallel for better performance
  LTasks[0] := TTask.Create(
    procedure
    begin
      LMetadataJson := FMetadata.ToJsonString;
    end);

  LTasks[1] := TTask.Create(
    procedure
    begin
      LTransactionJson := FTransaction.ToJsonString;
    end);

  LTasks[2] := TTask.Create(
    procedure
    var
      LSpan: TSpan;
    begin
      LSpansJson := '';
      if Assigned(FSpanList) then
        for LSpan in FSpanList do
          if LSpan <> nil then
            LSpansJson := LSpansJson + IfThen(not LSpansJson.IsEmpty, XndJsonSeparator) + LSpan.ToJsonString;
    end);

  LTasks[3] := TTask.Create(
    procedure
    var
      LError: TError;
    begin
      LErrorsJson := '';
      if Assigned(FErrorList) then
        for LError in FErrorList do
          if LError <> nil then
            LErrorsJson := LErrorsJson + IfThen(not LErrorsJson.IsEmpty, XndJsonSeparator) + LError.ToJsonString;
    end);

  LTasks[4] := TTask.Create(
    procedure
    var
      LLogEntry: TAPMLog;
    begin
      LLogsJson := '';
      if Assigned(FLogList) then
        for LLogEntry in FLogList do
          if LLogEntry <> nil then
            LLogsJson := LLogsJson + IfThen(not LLogsJson.IsEmpty, XndJsonSeparator) + LLogEntry.ToJsonString;
    end);

  // Start all tasks
  for var LTask in LTasks do
    LTask.Start;

  // Wait for all serializations to complete
  TTask.WaitForAll(LTasks);

  // Add serialized content in correct order
  LValue :=
    LMetadataJson + XndJsonSeparator + LTransactionJson +
    IfThen(not LSpansJson.IsEmpty, XndJsonSeparator) + LSpansJson +
    IfThen(not LErrorsJson.IsEmpty, XndJsonSeparator) + LErrorsJson +
    IfThen(not LLogsJson.IsEmpty, XndJsonSeparator) + LLogsJson;

  // Collect metrics (already parallel internally)
  TMetricSets.CollectAsync(
    procedure(AMetric: string)
    begin
      if not AMetric.IsEmpty then
        LValue := LValue + XndJsonSeparator + AMetric;
    end);

  TQueueSingleton.StackUp(LValue, Header);
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
