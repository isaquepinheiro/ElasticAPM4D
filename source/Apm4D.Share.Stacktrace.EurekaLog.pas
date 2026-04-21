{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.Share.Stacktrace.EurekaLog;

interface

uses
  System.Classes,
  Apm4D.Share.Stacktrace;

type
  TStacktraceEurekaLog = class(TStackTracer)
  private const
    MAX_FRAMES = 15;
  private
    FStackTrace: TArray<TStacktrace>;
  protected
    function GetStackList: TStringList; virtual;
    function IsIgnoreUnit(const AUnitName: string): Boolean;
    function ExtractValue(const AStr, ARegEX: string): string;
    function GetUnitName(const AStr: string): string;
    function GetLine(const AStr: string): Integer;
    function GetFunctionName(const AStr: string): string;
  public
    constructor Create;
    function Get: TArray<TStacktrace>; override;
    function GetCulprit: string; override;
  end;

implementation

uses
{$IFDEF EUREKALOG}
  ExceptionLog7, ECallStack,
{$ENDIF}
  System.SysUtils, System.RegularExpressions;

{ TStacktraceEurekaLog }

constructor TStacktraceEurekaLog.Create;
var
  LStackList: TStringList;
  LStacktrace: TStacktrace;
  LLineIndex: Integer;
  LFrameCount: Integer;
begin
  FStackTrace := [];
  LFrameCount := 0;
  LStackList := GetStackList;
  try
    for LLineIndex := 0 to Pred(LStackList.Count) do
    begin
      if LFrameCount >= MAX_FRAMES then
        Break;

      if LStackList.Strings[LLineIndex].Trim.IsEmpty then
        Continue;

      LStacktrace := TStacktrace.Create;
      try
        LStacktrace.filename := GetUnitName(LStackList.Strings[LLineIndex]);
        LStacktrace.lineno := GetLine(LStackList.Strings[LLineIndex]);
        LStacktrace.&function := GetFunctionName(LStackList.Strings[LLineIndex]);
        LStacktrace.Context_line := LStackList.Strings[LLineIndex].Trim;

        if IsIgnoreUnit(LStacktrace.filename) then
        begin
          LStacktrace.Free;
          Continue;
        end;

        FStackTrace := FStackTrace + [LStacktrace];
        Inc(LFrameCount);
      except
        LStacktrace.Free;
      end;
    end;
  finally
    LStackList.Free;
  end;
end;

function TStacktraceEurekaLog.ExtractValue(const AStr, ARegEX: string): string;
var
  LMatch: TMatch;
begin
  try
    LMatch := TRegEx.Match(AStr, ARegEX);
    if LMatch.Success then
    begin
      if LMatch.Groups.Count > 1 then
        Exit(LMatch.Groups.Item[1].Value)
      else
        Exit(LMatch.Value);
    end;
  except
  end;
  Result := '';
end;

function TStacktraceEurekaLog.Get: TArray<TStacktrace>;
begin
  Result := FStackTrace;
end;

function TStacktraceEurekaLog.GetCulprit: string;
var
  LStack: TStacktrace;
begin
  if Length(FStackTrace) = 0 then
    Exit('unknown');

  LStack := FStackTrace[0];
  if not LStack.&function.IsEmpty then
    Exit(LStack.&function);

  Result := LStack.filename;
end;

function TStacktraceEurekaLog.GetFunctionName(const AStr: string): string;
begin
  // EurekaLog often has format: Unit.Function
  Result := ExtractValue(AStr, '([a-zA-Z0-9_]+\.[a-zA-Z0-9_]+)');
end;

function TStacktraceEurekaLog.GetLine(const AStr: string): Integer;
begin
  Result := StrToIntDef(ExtractValue(AStr, 'line (\d+)'), 0);
end;

function TStacktraceEurekaLog.GetStackList: TStringList;
{$IFDEF EUREKALOG}
var
  LCallStack: TEurekaBaseStackList;
{$ENDIF}
begin
  Result := TStringList.Create;
{$IFDEF EUREKALOG}
  LCallStack := GetCurrentCallStack;
  try
    Result.Text := LCallStack.ToString;
  finally
    LCallStack.Free;
  end;
{$ENDIF}
end;

function TStacktraceEurekaLog.GetUnitName(const AStr: string): string;
begin
  Result := ExtractValue(AStr, '([a-zA-Z0-9_]+\.pas)');
  if Result.IsEmpty then
    Result := 'unknown';
    
  if not Result.ToLower.EndsWith('.pas') and (Result <> 'unknown') then
    Result := Result + '.pas';
end;

function TStacktraceEurekaLog.IsIgnoreUnit(const AUnitName: string): Boolean;
const
  IGNORE_UNITS: array [0 .. 1] of string = ('ExceptionLog', 'Apm4D');
var
  LCurrent: string;
begin
  Result := False;
  for LCurrent in IGNORE_UNITS do
  begin
    if AUnitName.ToLower.StartsWith(LCurrent.ToLower) then
      Exit(True);
  end;
end;

end.
