{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.HttpClient.Mock;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Apm4D.Share.Types;

type
  TApm4DHttpClientMockCall = record
    Url: string;
    SecretToken: string;
    Traceparent: string;
    Body: string;
  end;

  TApm4DHttpClientMock = class(TInterfacedObject, IApm4DHttpClient)
  private
    FCalls: TList<TApm4DHttpClientMockCall>;
    FResponseCode: Integer;
    FResponseCodes: TQueue<Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    function Post(const AUrl, ASecretToken, ATraceparent, ABody: string): Integer;
    
    procedure SetResponseCode(const ACode: Integer);
    procedure QueueResponseCode(const ACode: Integer);
    property Calls: TList<TApm4DHttpClientMockCall> read FCalls;
  end;

implementation

{ TApm4DHttpClientMock }

constructor TApm4DHttpClientMock.Create;
begin
  FCalls := TList<TApm4DHttpClientMockCall>.Create;
  FResponseCodes := TQueue<Integer>.Create;
  FResponseCode := 200;
end;

destructor TApm4DHttpClientMock.Destroy;
begin
  FCalls.Free;
  FResponseCodes.Free;
  inherited;
end;

function TApm4DHttpClientMock.Post(const AUrl, ASecretToken, ATraceparent, ABody: string): Integer;
var
  LCall: TApm4DHttpClientMockCall;
begin
  LCall.Url := AUrl;
  LCall.SecretToken := ASecretToken;
  LCall.Traceparent := ATraceparent;
  LCall.Body := ABody;
  FCalls.Add(LCall);

  if FResponseCodes.Count > 0 then
    Result := FResponseCodes.Dequeue
  else
    Result := FResponseCode;
end;

procedure TApm4DHttpClientMock.QueueResponseCode(const ACode: Integer);
begin
  FResponseCodes.Enqueue(ACode);
end;

procedure TApm4DHttpClientMock.SetResponseCode(const ACode: Integer);
begin
  FResponseCode := ACode;
end;

end.
