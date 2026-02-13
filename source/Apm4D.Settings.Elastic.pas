unit Apm4D.Settings.Elastic;

interface

type
  TElasticSettings = class
  strict private
    FUrl: string;
    FSecret: string;
    FUpdateTime: Integer;
    FMaxJsonPerThread: Integer;
  private const
    RESOURCE_URL = 'intake/v2/events';
  private
    procedure SetUrl(const Value: string);
    function GetUrl: string;
  public
    constructor Create;

    property Url: string read GetUrl write SetUrl;
    property Secret: string read FSecret write FSecret;
    property UpdateTime: Integer read FUpdateTime write FUpdateTime;
    property MaxJsonPerThread: Integer read FMaxJsonPerThread write FMaxJsonPerThread;
  end;

implementation

Uses
  SysUtils, StrUtils;

{ TElasticSettings }

constructor TElasticSettings.Create;
begin
  inherited;
  FUrl := '';
  FSecret := '';
  FUpdateTime := 60000;
  FMaxJsonPerThread := 60;
end;

function TElasticSettings.GetUrl: string;
begin
  if FUrl.IsEmpty then
    FUrl := 'http://127.0.0.1:8200/' + RESOURCE_URL;
  Result := FUrl;
end;

procedure TElasticSettings.SetUrl(const Value: string);
begin
  FUrl := Value + IfThen(not Value.EndsWith('/'), '/') + RESOURCE_URL;
end;

end.
