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
  protected
    procedure Execute; override;
  public
    constructor Create(const AUrl: string; const ASecret: string = '');
    destructor Destroy; override;

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
end;

destructor TSendThread.Destroy;
begin
  FreeAndNil(FInternalList);
  inherited;
end;

procedure TSendThread.Execute;
var
  LDataSend: TDataSend;
  LHttpCode: Integer;
  LOcurrConnectionError: Boolean;
  LHttpClient: IApm4DHttpClient;
begin
  inherited;
  LOcurrConnectionError := False;
  FResult := trSending;
  LHttpClient := TApm4DSettings.CreateHttpClient;
  try
    for LDataSend in FInternalList do
    begin
      LHttpCode := LHttpClient.Post(FURL, FSecret, LDataSend.Header, LDataSend.Json);
      if LHttpCode = 429 then
      begin
        Sleep(1000);
        Inc(FTotalErrors);
        LHttpCode := LHttpClient.Post(FURL, FSecret, LDataSend.Header, LDataSend.Json);
      end;
      if (LHttpCode >= 500) or (LHttpCode = 429) then
      begin
        if not LOcurrConnectionError then
        begin
          Inc(FConnectionError);
          LOcurrConnectionError := True;
        end;
        Inc(FTotalErrors);
        Terminate;
      end;
    end;
  finally
    if not LOcurrConnectionError then
      FConnectionError := 0;
    FResult := trFinished;
  end;
end;

end.
