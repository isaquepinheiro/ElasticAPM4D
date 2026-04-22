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
  System.RegularExpressions,
  Apm4D.Share.Stacktrace;

type
  TStacktraceEurekaLog = class(TStackTracer)
  private const
    MAX_FRAMES = 15;
  private
    class var FRegExFunction: TRegEx;
    class var FRegExLine: TRegEx;
    class var FRegExUnit: TRegEx;
  protected
    function GetStackList: TStringList; virtual;
    function IsIgnoreUnit(const AUnitName: string): Boolean;
    function ExtractValue(const AStr: string; const ARegEX: TRegEx): string;
    function GetUnitName(const AStr: string): string;
    function GetLine(const AStr: string): Integer;
    function GetFunctionName(const AStr: string): string;
  public
    constructor Create; override;
    class constructor Create;
    function GetCulprit: string; override;
  end;

implementation

uses
{$IFDEF EUREKALOG}
  ExceptionLog7, ECallStack,
{$ENDIF}
  System.SysUtils;

{ TStacktraceEurekaLog }

class constructor TStacktraceEurekaLog.Create;
begin
  FRegExFunction := TRegEx.Create('([a-zA-Z0-9_]+\.[a-zA-Z0-9_]+)', [roCompiled]);
  FRegExLine := TRegEx.Create('line (\d+)', [roCompiled]);
  FRegExUnit := TRegEx.Create('([a-zA-Z0-9_]+\.pas)', [roCompiled]);
end;

constructor TStacktraceEurekaLog.Create;
var
  LStackList: TStringList;
  LStacktrace: TStacktrace;
  LLineIndex: Integer;
  LFrameCount: Integer;
begin
  inherited Create;
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

function TStacktraceEurekaLog.ExtractValue(const AStr: string; const ARegEX: TRegEx): string;
var
  LMatch: TMatch;
begin
  try
    LMatch := ARegEX.Match(AStr);
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
  Result := ExtractValue(AStr, FRegExFunction);
end;

function TStacktraceEurekaLog.GetLine(const AStr: string): Integer;
begin
  Result := StrToIntDef(ExtractValue(AStr, FRegExLine), 0);
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
  Result := ExtractValue(AStr, FRegExUnit);
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
