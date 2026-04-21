{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.Share.Types;

interface

uses 
  SysUtils;

type
  TOutcome = (success, failure, unknown);

  EElasticAPM4DException = class(Exception);

  ETransactionNotFound = class(EElasticAPM4DException)

  end;

  IApm4DHttpClient = interface
    ['{8844D1EB-D65D-4F29-B0F3-E2E1A299F7A2}']
    function Post(const AUrl, ASecretToken, ATraceparent, ABody: string): Integer;
  end;

  TApm4DHttpClientFactory = function: IApm4DHttpClient;

implementation

end.
