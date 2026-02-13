{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.Metricset.Formatter;

interface

uses
  Classes, SysUtils, StrUtils;

type
  TSampleType = (gauge, counter, histogram);

  TSampleUnit = (
    msuUnknown, msuPercent, msuByte, msuNanos, msuMicros, msuMicrossecunds, msuSecunds, msuMinuts, msuHours, msuDays);

  TMetricsetFormatter = class
  private
    FList: TStringList;
    function UnitToString(const AUnit: TSampleUnit): string;
    function TypeToString(const AType: TSampleType): string;
    function FormatName(const AName: string; const AUnit: TSampleUnit; const AType: TSampleType): string;
  public
    constructor Create;
    destructor Destroy; override;

    // Type holds an optional metric type: gauge, counter, or histogram. If Type is unknown, it will be ignored.
    // Unit holds an optional unit for the metric.
    // - \"percent\" (value is in the range [0,1])
    // - \"byte\"
    // - a time unit: \"nanos\", \"micros\", \"ms\", \"s\", \"m\", \"h\", \"d\"
    // If Unit is unknown, it will be ignored.

    procedure AddPercentageGauge(const AName: string; const AValue: Currency);
    procedure AddBytesGauge(const AName: string; const AValue: UInt64);
    procedure AddDecimalGauge(const AName: string; const AValue: Currency);
    procedure AddHistogram(const AName: string; const AUnit: TSampleUnit; const AValues: TArray<Currency>);
    procedure AddCustom(const AName: string; const AUnit: TSampleUnit; const AType: TSampleType; const AValue: Currency);
    
    procedure Clear;

    function ToJsonString: string;
  end;

function FormatCurr(const AValue: Currency): string;

implementation

function FormatCurr(const AValue: Currency): string;
begin
  Result := StringReplace(FormatFloat('0.00', AValue), ',', '.', []);
end;

{ TMetricsetFormatter }

procedure TMetricsetFormatter.AddCustom(const AName: string;
  const AUnit: TSampleUnit; const AType: TSampleType; const AValue: Currency);
begin
  FList.Add(Format('"%s":{"value":%s}', [FormatName(AName, AUnit, AType), FormatCurr(AValue)]));
end;

procedure TMetricsetFormatter.AddHistogram(const AName: string; const AUnit: TSampleUnit; const AValues: TArray<Currency>);

  function ArrayToString: string;
  var
    Value: Currency;
  begin
    Result := '';
    for Value in AValues do
      Result := Result + IfThen(not Result.IsEmpty, ',') + FormatCurr(Value);
  end;

begin
  FList.Add(Format('"%s":{"values":[%s]}', [FormatName(AName, AUnit, histogram), ArrayToString]));
end;

procedure TMetricsetFormatter.AddPercentageGauge(const AName: string; const AValue: Currency);
begin
  // Elastic APM requires percentage values in the range [0,1], not [0,100]
  // So we divide by 100 to convert from percentage to decimal
  AddCustom(AName, msuPercent, gauge, AValue / 100);
end;

procedure TMetricsetFormatter.AddBytesGauge(const AName: string; const AValue: UInt64);
begin
  // For byte metrics, we add directly without unit suffix as per Elastic APM spec
  // Format: "metric.name":{"value":12345}
  FList.Add(Format('"%s":{"value":%u}', [AName, AValue]));
end;

procedure TMetricsetFormatter.AddDecimalGauge(const AName: string; const AValue: Currency);
begin
  // For metrics with complete names (e.g., already have .pct suffix), add directly without unit suffix
  // Format: "metric.name":{"value":0.50}
  FList.Add(Format('"%s":{"value":%s}', [AName, FormatCurr(AValue)]));
end;

constructor TMetricsetFormatter.Create;
begin
  FList := TStringList.Create;
  FList.Delimiter := ',';
  FList.QuoteChar := #0;
  FList.StrictDelimiter := true;
end;

destructor TMetricsetFormatter.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TMetricsetFormatter.Clear;
begin
  FList.Clear;
end;

function TMetricsetFormatter.FormatName(const AName: string; const AUnit: TSampleUnit; const AType: TSampleType): string;
begin
  Result := Format('%s%s.%s', [IfThen(not AName.IsEmpty, AName + '.'), UnitToString(AUnit), TypeToString(AType)]);
end;

function TMetricsetFormatter.ToJsonString: string;
begin
  Result := Format('"samples":{%s}', [FList.DelimitedText]);
end;

function TMetricsetFormatter.TypeToString(const AType: TSampleType): string;
const
  TYPE_STR: array [TSampleType] of string = ('gauge', 'counter', 'histogram');
begin
  Result := TYPE_STR[AType];
end;

function TMetricsetFormatter.UnitToString(const AUnit: TSampleUnit): string;
const
  UNIT_STR: array [TSampleUnit] of string = (
    'unknown', 'percent', 'byte', 'nanos', 'micros', 'ms', 's', 'm', 'h', 'd');
begin
  Result := UNIT_STR[AUnit];
end;

end.
