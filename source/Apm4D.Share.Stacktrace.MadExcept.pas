{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.Share.Stacktrace.MadExcept;

interface

uses
  System.Classes,
  System.RegularExpressions,
  Apm4D.Share.Stacktrace;

type
  TStacktraceMadExcept = class(TStackTracer)
  private const
    MAX_FRAMES = 15;
  private
    FStackTrace: TArray<TStacktrace>;
    class var FRegExUnit1: TRegEx;
    class var FRegExUnit2: TRegEx;
    class var FRegExLine: TRegEx;
    class var FRegExFunction1: TRegEx;
    class var FRegExFunction2: TRegEx;
  protected
    function GetStackList: TStringList; virtual;
    function IsIgnoreUnit(const AUnitName: string): Boolean;
    function ExtractValue(const AStr: string; const ARegEX: TRegEx): string;
    function GetUnitName(const AStr: string): string;
    function GetLine(const AStr: string): Integer;
    function GetFunctionName(const AStr: string): string;
  public
    constructor Create;
    class constructor Create;
    function Get: TArray<TStacktrace>; override;
    function GetCulprit: string; override;
  end;

implementation

uses
{$IFDEF madExcept}
  madExcept,
{$ENDIF}
  System.SysUtils;

{ TStacktraceMadExcept }

class constructor TStacktraceMadExcept.Create;
begin
  FRegExUnit1 := TRegEx.Create('\s+([a-zA-Z0-9_]+\.pas)\s+', [roCompiled]);
  FRegExUnit2 := TRegEx.Create('\s+([a-zA-Z0-9_]+)\s+\d+\s+', [roCompiled]);
  FRegExLine := TRegEx.Create('\s+(\d+)\s+', [roCompiled]);
  FRegExFunction1 := TRegEx.Create('([a-zA-Z0-9_]+\.[a-zA-Z0-9_]+)$', [roCompiled]);
  FRegExFunction2 := TRegEx.Create('([a-zA-Z0-9_]+)$', [roCompiled]);
end;

constructor TStacktraceMadExcept.Create;
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

function TStacktraceMadExcept.ExtractValue(const AStr: string; const ARegEX: TRegEx): string;
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

function TStacktraceMadExcept.Get: TArray<TStacktrace>;
begin
  Result := FStackTrace;
end;

function TStacktraceMadExcept.GetCulprit: string;
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

function TStacktraceMadExcept.GetFunctionName(const AStr: string): string;
begin
  // MadExcept format: ... [Unit] [Line] [Function]
  // We try to extract the last part of the line which is usually the function name
  Result := ExtractValue(AStr, FRegExFunction1);
  if Result.IsEmpty then
    Result := ExtractValue(AStr, FRegExFunction2);
end;

function TStacktraceMadExcept.GetLine(const AStr: string): Integer;
begin
  // Try to find a standalone number which is often the line number in MadExcept
  Result := StrToIntDef(ExtractValue(AStr, FRegExLine), 0);
end;

function TStacktraceMadExcept.GetStackList: TStringList;
begin
  Result := TStringList.Create;
{$IFDEF madExcept}
  Result.Text := madExcept.GetStackTrace;
{$ENDIF}
end;

function TStacktraceMadExcept.GetUnitName(const AStr: string): string;
begin
  Result := ExtractValue(AStr, FRegExUnit1);
  if Result.IsEmpty then
    Result := ExtractValue(AStr, FRegExUnit2); // Unit before line number
    
  if Result.IsEmpty then
    Result := 'unknown';
    
  if not Result.ToLower.EndsWith('.pas') and (Result <> 'unknown') then
    Result := Result + '.pas';
end;

function TStacktraceMadExcept.IsIgnoreUnit(const AUnitName: string): Boolean;
const
  IGNORE_UNITS: array [0 .. 2] of string = ('madExcept', 'madStackTrace', 'Apm4D');
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
