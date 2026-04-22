{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.Share.Stacktrace.Jcl;

interface

uses 
  System.Classes,
  System.RegularExpressions,
  Apm4D.Share.Stacktrace;
  
type
  TStacktraceJCL = class(TStackTracer)
  private const
    MAX_FRAMES = 15; // Limit stacktrace to 15 most relevant frames
  private
    class var FRegExValid: TRegEx;
    class var FRegExClassName: TRegEx;
    class var FRegExFunctionName1: TRegEx;
    class var FRegExFunctionName2: TRegEx;
    class var FRegExContextLine1: TRegEx;
    class var FRegExContextLine2: TRegEx;
    class var FRegExLine: TRegEx;
    class var FRegExUnitNames: array[0..3] of TRegEx;
  protected
    function ExtractValue(const AStr: string; const ARegEX: TRegEx): string;
    function GetLine(const AStr: string): Integer;
    function GetUnitName(const AStr: string): string;
    function GetClassName(const AStr: string): string;
    function GetFunctionName(const AStr: string): string;
    function GetContextLine(const AStr: string): string;
    function GetStackList: TStringList; virtual;
    function IsValidStacktrace(const AStr: string): Boolean;
    function IsIgnoreUnit(const AUnitName: string): Boolean;
  public
    constructor Create; override;
    class constructor Create;

    function GetCulprit: string; override;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
{$IFDEF jcl}
  JclDebug,
{$ENDIF}
{$ENDIF} System.IOUtils, System.SysUtils, System.Rtti;

{ TStacktraceJCL }

class constructor TStacktraceJCL.Create;
begin
  FRegExValid := TRegEx.Create('(?<=\])(.*?)(?=[(\+])', [roCompiled]);
  FRegExClassName := TRegEx.Create('(\T[a-zA-Z0-9_]+)', [roCompiled]);
  FRegExFunctionName1 := TRegEx.Create('(?<=\])(.*?)(?=[(\+])', [roCompiled]);
  FRegExFunctionName2 := TRegEx.Create('(?<=\])(.*)', [roCompiled]);
  FRegExContextLine1 := TRegEx.Create('(?<=\])(.*?)(?=\+)', [roCompiled]);
  FRegExContextLine2 := TRegEx.Create('(?<=\])(.*)', [roCompiled]);
  FRegExLine := TRegEx.Create('\(Line (?<linha>\d+)', [roCompiled]);
  
  FRegExUnitNames[0] := TRegEx.Create('\ ?"(?<arquivo>[0-9_a-zA-Z.]+)".*\)', [roCompiled]);
  FRegExUnitNames[1] := TRegEx.Create('\] (vcl\.[a-zA-Z0-9_]+|Vcl\.[a-zA-Z0-9_]+)', [roCompiled]);
  FRegExUnitNames[2] := TRegEx.Create('\] (system\.[a-zA-Z0-9_]+|System\.[a-zA-Z0-9_]+)', [roCompiled]);
  FRegExUnitNames[3] := TRegEx.Create('\] ([a-zA-Z0-9_]+)', [roCompiled]);
end;

constructor TStacktraceJCL.Create;
var
  LStackList: TStringList;
  LStacktrace: TStacktrace;
  LLine: Integer;
  LFrameCount: Integer;
begin
  FStackTrace := [];
  LFrameCount := 0;
  LStackList := GetStackList;
  try
    for LLine := 0 to Pred(LStackList.Count) do
    begin
      if LFrameCount >= MAX_FRAMES then
        Break;

      if not IsValidStacktrace(LStackList.Strings[LLine]) then
        Continue;

      LStacktrace := TStacktrace.Create;
      try
        LStacktrace.lineno := GetLine(LStackList.Strings[LLine]);
        LStacktrace.module := GetClassName(LStackList.Strings[LLine]);
        LStacktrace.filename := GetUnitName(LStackList.Strings[LLine]);
        LStacktrace.&function := GetFunctionName(LStackList.Strings[LLine]);
        LStacktrace.Context_line := GetContextLine(LStackList.Strings[LLine]);

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

function TStacktraceJCL.IsValidStacktrace(const AStr: string): Boolean;
begin
  Result := (AStr.Contains('[') and AStr.Contains(']')) and
            (not ExtractValue(AStr, FRegExValid).Trim.IsEmpty);
end;

function TStacktraceJCL.ExtractValue(const AStr: string; const ARegEX: TRegEx): string;
var
  LMath: TMatch;
begin
  try
    LMath := ARegEX.Match(AStr);
    if LMath.Success then
    begin
      if LMath.Groups.Count > 1 then
        Exit(LMath.Groups.Item[1].Value)
      else
        Exit(LMath.Value);
    end;
  except
    // Silent fail for regex
  end;
  Result := '';
end;

function TStacktraceJCL.GetClassName(const AStr: string): string;
begin
  Result := ExtractValue(AStr, FRegExClassName);
end;

function TStacktraceJCL.GetFunctionName(const AStr: string): string;
begin
  Result := ExtractValue(AStr, FRegExFunctionName1).Trim;
  if Result.IsEmpty then
    Result := ExtractValue(AStr, FRegExFunctionName2).Trim;
end;

function TStacktraceJCL.GetContextLine(const AStr: string): string;
begin
  Result := ExtractValue(AStr, FRegExContextLine1);
  if Result.IsEmpty then
    Result := ExtractValue(AStr, FRegExContextLine2);
    
  if (not Result.IsEmpty) and (Pos('(', Result) > 0) and (not Result.Contains(')')) then
    Result := Result + ')';
end;

function TStacktraceJCL.GetCulprit: string;
var
  LStack: TStacktrace;
begin
  if Length(FStackTrace) = 0 then
    Exit('unknown');

  LStack := FStackTrace[0];
  if not LStack.&function.IsEmpty then
    Exit(LStack.&function);

  if not LStack.module.IsEmpty then
    Exit(LStack.module);

  Result := LStack.filename;
end;

function TStacktraceJCL.GetLine(const AStr: string): Integer;
begin
  Result := StrToIntDef(ExtractValue(AStr, FRegExLine), 0);
end;

// JclCreateStackList
function TStacktraceJCL.GetStackList: TStringList;
{$IFDEF MSWINDOWS}
{$IFDEF jcl}
var
  LStackInfo: TJclStackInfoList;
{$ENDIF}
{$ENDIF}
begin
  Result := TStringList.Create;
{$IFDEF MSWINDOWS}
{$IFDEF jcl}
  LStackInfo := JclCreateStackList(True, 0, nil);
  try
    LStackInfo.AddToStrings(Result, True, True, True, True);
  finally
    LStackInfo.Free;
  end;
{$ENDIF}
{$ENDIF}
end;

function TStacktraceJCL.GetUnitName(const AStr: string): string;
  procedure FormatExtension(var AStr: string);
  begin
    if not AStr.ToLower.EndsWith('.pas') then
      AStr := AStr + '.pas';
  end;

var
  LIndex: Integer;
begin
  for LIndex := 0 to Pred(Length(FRegExUnitNames)) do
  begin
    Result := ExtractValue(AStr, FRegExUnitNames[LIndex]);
    if not Result.IsEmpty then
      Break;
  end;
  if Result.IsEmpty then
    Result := 'unknown';
  FormatExtension(Result);
end;

function TStacktraceJCL.IsIgnoreUnit(const AUnitName: string): Boolean;
const
  Units: array [0 .. 1] of string =
    (
    'jcldebug', 'Apm4D'
    );
var
  LCurrent: string;
begin
  for LCurrent in Units do
  begin
    Result := AUnitName.ToLower.Trim.StartsWith(LCurrent.ToLower);
    if Result then
      Exit;
  end;
end;


end.
