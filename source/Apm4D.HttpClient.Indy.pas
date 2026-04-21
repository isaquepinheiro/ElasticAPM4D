{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.HttpClient.Indy;

interface

uses
  System.SysUtils,
  System.Classes,
  Apm4D.Share.Types,
  IdHttp,
  IdSSLOpenSSL;

type
  TApm4DIdHttpClient = class(TInterfacedObject, IApm4DHttpClient)
  private
    procedure _SaveLog(const ABody: string; const ARespCode: Integer; const AMessage: string);
  public
    function Post(const AUrl, ASecretToken, ATraceparent, ABody: string): Integer;
  end;

  function TApm4DIdHttpClientFactory: IApm4DHttpClient;

implementation

uses
  Vcl.Forms,
  System.IOUtils,
  Apm4D.Settings;

{ TApm4DIdHttpClient }

function TApm4DIdHttpClient.Post(const AUrl, ASecretToken, ATraceparent, ABody: string): Integer;
var
  LHttp: TIdHTTP;
  LDataSend, LStream: TStringStream;
  LSSLHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  if ABody = '' then
    Exit(200);

  LHttp := TIdHTTP.Create(nil);
  try
    if AUrl.StartsWith('https') then
    begin
      LSSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(LHttp);
      LSSLHandler.SSLOptions.SSLVersions := [sslvTLSv1_2];
      LHttp.IOHandler := LSSLHandler;
    end;

    LDataSend := TStringStream.Create(ABody, TEncoding.UTF8);
    LStream := TStringStream.Create('');
    try
      LHttp.Request.ContentType := 'application/x-ndjson';
      LHttp.Request.Charset := 'gzip';
      LHttp.Request.CustomHeaders.AddValue('elastic-apm-traceparent', ATraceparent);
      if not ASecretToken.IsEmpty then
      begin
        LHttp.Request.CustomHeaders.AddValue('Authorization', 'Bearer ' + ASecretToken);
      end;

      try
        LHttp.Post(AUrl, LDataSend, LStream);
        Result := 200;
        _SaveLog(ABody, Result, 'Ok');
      except
        on E: EIdHTTPProtocolException do
        begin
          Result := E.ErrorCode;
          _SaveLog(ABody, Result, E.Message);
        end;
        on E: Exception do
        begin
          Result := 500;
          _SaveLog(ABody, Result, E.Message);
        end;
      end;
    finally
      LDataSend.Free;
      LStream.Free;
    end;
  finally
    LHttp.Free;
  end;
end;

procedure TApm4DIdHttpClient._SaveLog(const ABody: string; const ARespCode: Integer; const AMessage: string);
var
  LLog: TStringList;
begin
  if TApm4DSettings.Log.OutputFileDir.IsEmpty then
    Exit;

  LLog := TStringList.Create;
  try
    LLog.Add(AMessage);
    LLog.Add(ABody);
    LLog.SaveToFile(IncludeTrailingPathDelimiter(TApm4DSettings.Log.OutputFileDir) + 
      TPath.GetFileNameWithoutExtension(Application.ExeName) + '_' + ARespCode.ToString + '_' + 
      FormatDateTime('hh-mm-sss', Now) + '.log');
  finally
    LLog.Free;
  end;
end;

function TApm4DIdHttpClientFactory: IApm4DHttpClient;
begin
  Result := TApm4DIdHttpClient.Create;
end;

end.
