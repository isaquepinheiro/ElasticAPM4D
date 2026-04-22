{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.Error;

interface

uses
  Apm4D.Share.Stacktrace,
  Apm4D.Share.Context,
  Apm4D.Error.Exception,
  Apm4D.Serializer;

type
  TError = class
  private
    FCulprit: String;
    FException: TErrorException;
    FId: String;
    FParent_id: String;
    FTrace_id: String;
    FTransaction_id: String;
    FTimestamp: Int64;
    Fcontext: TContext;
    FStackTracer: TStackTracer;
  public
    constructor Create(const ATraceId, ATransactionId, AParentId: string; const AStackTracerFactory: TStackTracerFactory);
    destructor Destroy; override;

    function ToJsonString: string;

    // <summary>
    // Culprit identifies the function call which was the primary perpetrator of this event
    // </summary>
    property Culprit: String read FCulprit write FCulprit;
    property Context: TContext read Fcontext;
    property Exception: TErrorException read FException;
    property Id: string read FId;
    property Parent_id: string read FParent_id;
    property Trace_id: string read FTrace_id;
    property Transaction_id: string read FTransaction_id;
    property Timestamp: Int64 read FTimestamp;
  end;

implementation

uses
  System.SysUtils, Apm4D.Share.Uuid, Apm4D.Share.TimestampEpoch;

{ TError }

constructor TError.Create(const ATraceId, ATransactionId, AParentId: string; const AStackTracerFactory: TStackTracerFactory);
begin
  FId := TUUid.Get128b;
  FException := TErrorException.Create;
  Fcontext := TContext.Create;
  FTimestamp := TTimestampEpoch.Get(now);
  FTrace_id := ATraceId;
  FTransaction_id := ATransactionId;
  FParent_id := AParentId;
  FCulprit := '';
  
  FStackTracer := nil;
  if Assigned(AStackTracerFactory) then
    FStackTracer := AStackTracerFactory();

  if Assigned(FStackTracer) then
  begin
    FException.Stacktrace := FStackTracer.Get;
    FCulprit := FStackTracer.GetCulprit;
  end;
end;

destructor TError.Destroy;
begin
  FException.Free;
  Fcontext.Free;
  if Assigned(FStackTracer) then
    FStackTracer.Free;
  inherited;
end;

function TError.ToJsonString: string;
begin
  Result := TApm4DSerializer.ToJSON(Self, 'error');
end;

end.
