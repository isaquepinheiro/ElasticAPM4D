{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.SendThread;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  Vcl.ExtCtrls;

type
  TDataSend = Record
    Json: Widestring;
    Header: string;
  End;

  TDataSendList = TList<TDataSend>;

  TThreadResult = (trSuspended, trFinished, trSending);

  TSendThread = class(TThread)
  private
    FURL: string;
    FSecret: string;
    FTotalErrors: Integer;
    FConnectionError: Integer;
    FInternalList: TDataSendList;
    FResult: TThreadResult;
    FEvent: TEvent;
    function _Wait(const AMS: Integer): Boolean;
    function _CalculateDelay(const AAttempt: Integer): Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AUrl: string; const ASecret: string = '');
    destructor Destroy; override;
    procedure Terminate;

    property InternalList: TDataSendList read FInternalList write FInternalList;
    property Result: TThreadResult read FResult;

    property TotalErrors: Integer read FTotalErrors write FTotalErrors;
    property ConnectionError: Integer read FConnectionError write FConnectionError;
  end;

implementation

uses
  Apm4D.Settings, Apm4D.Share.Types;


{ TSendThread }

constructor TSendThread.Create(const AUrl: string; const ASecret: string);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FURL := AUrl;
  FSecret := ASecret;
  FInternalList := TDataSendList.Create;
  FResult := trSuspended;
  FEvent := TEvent.Create(nil, True, False, '');
end;

destructor TSendThread.Destroy;
begin
  FEvent.Free;
  FreeAndNil(FInternalList);
  inherited;
end;

procedure TSendThread.Terminate;
begin
  inherited Terminate;
  FEvent.SetEvent;
end;

function TSendThread._Wait(const AMS: Integer): Boolean;
begin
  Result := FEvent.WaitFor(AMS) = wrSignaled;
end;

function TSendThread._CalculateDelay(const AAttempt: Integer): Integer;
var
  LBaseDelay: Double;
  LJitter: Integer;
begin
  // Formula: delay = min(InitialDelay * 2^attempt, MaxDelay) + jitter
  LBaseDelay := TApm4DSettings.Elastic.InitialRetryDelay * (1 shl AAttempt);
  if LBaseDelay > TApm4DSettings.Elastic.MaxRetryDelay then
    LBaseDelay := TApm4DSettings.Elastic.MaxRetryDelay;

  // Add jitter (random +/- 10%)
  LJitter := Random(Trunc(LBaseDelay * 0.2)) - Trunc(LBaseDelay * 0.1);
  Result := Trunc(LBaseDelay) + LJitter;

  if Result < 0 then
    Result := 0;
end;

procedure TSendThread.Execute;
var
  LDataSend: TDataSend;
  LHttpCode: Integer;
  LOcurrConnectionError: Boolean;
  LHttpClient: IApm4DHttpClient;
  LAttempt: Integer;
  LMaxRetries: Integer;
  LDelay: Integer;
begin
  inherited;
  LOcurrConnectionError := False;
  FResult := trSending;
  LHttpClient := TApm4DSettings.CreateHttpClient;
  LMaxRetries := TApm4DSettings.Elastic.MaxRetries;
  try
    for LDataSend in FInternalList do
    begin
      if Terminated then
        Break;

      LAttempt := 0;
      while LAttempt <= LMaxRetries do
      begin
        LHttpCode := LHttpClient.Post(FURL, FSecret, LDataSend.Header, LDataSend.Json);

        // Success: break retry loop
        if (LHttpCode >= 200) and (LHttpCode < 300) then
        begin
          LOcurrConnectionError := False;
          Break;
        end;

        // Retryable errors: 429 (Too Many Requests), 5xx (Server Errors)
        if (LHttpCode = 429) or (LHttpCode >= 500) then
        begin
          Inc(FTotalErrors);
          Inc(LAttempt);

          if LAttempt > LMaxRetries then
          begin
            Inc(FConnectionError);
            LOcurrConnectionError := True;
            Break; // Drop batch after max retries
          end;

          LDelay := _CalculateDelay(LAttempt);
          if _Wait(LDelay) then
            Exit; // Terminated during wait
        end
        else
        begin
          // Client error (4xx except 429) - Log and drop batch
          Inc(FTotalErrors);
          Break;
        end;
      end;
    end;
  finally
    if not LOcurrConnectionError then
      FConnectionError := 0;
    FResult := trFinished;
  end;
end;

end.
