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
  Apm4D.Share.Stacktrace;
  
type
  TStacktraceJCL = class(TStackTracer)
  private const
    MAX_FRAMES = 15; // Limit stacktrace to 15 most relevant frames
  private
    FStackTrace: TArray<TStacktrace>; 
  protected
    function ExtractValue(const AStr, ARegEX: string): string;
    function GetLine(const AStr: string): Integer;
    function GetUnitName(const AStr: string): string;
    function GetClassName(const AStr: string): string;
    function GetFunctionName(const AStr: string): string;
    function GetContextLine(const AStr: string): string;
    function GetStackList: TStringList; virtual;
    function IsValidStacktrace(const AStr: string): Boolean;
    function IsIgnoreUnit(const AUnitName: string): Boolean;
  public
    constructor Create;

    function Get: TArray<TStacktrace>; override;
    function GetCulprit: string; override;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
{$IFDEF jcl}
  JclDebug,
{$ENDIF}
{$ENDIF} System.IOUtils, System.SysUtils, System.Rtti, System.RegularExpressions;

{ TStacktraceJCL }

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
            (not ExtractValue(AStr, '(?<=\])(.*?)(?=[(\+])').Trim.IsEmpty);
end;

function TStacktraceJCL.ExtractValue(const AStr, ARegEX: string): string;
var
  LMath: TMatch;
begin
  try
    LMath := TRegEx.Match(AStr, ARegEX);
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
  Result := ExtractValue(AStr, '(\T[a-zA-Z0-9_]+)');
end;

function TStacktraceJCL.GetFunctionName(const AStr: string): string;
begin
  Result := ExtractValue(AStr, '(?<=\])(.*?)(?=[(\+])').Trim;
  if Result.IsEmpty then
    Result := ExtractValue(AStr, '(?<=\])(.*)').Trim;
end;

function TStacktraceJCL.GetContextLine(const AStr: string): string;
begin
  Result := ExtractValue(AStr, '(?<=\])(.*?)(?=\+)');
  if Result.IsEmpty then
    Result := ExtractValue(AStr, '(?<=\])(.*)');
    
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
  Result := StrToIntDef(ExtractValue(AStr, '\(Line (?<linha>\d+)'), 0);
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
const
  LIST_REGEx_UNIT_NAME: array [0 .. 3] of string = ('\ ?"(?<arquivo>[0-9_a-zA-Z.]+)".*\)',
    '\] (vcl\.[a-zA-Z0-9_]+|Vcl\.[a-zA-Z0-9_]+)', '\] (system\.[a-zA-Z0-9_]+|System\.[a-zA-Z0-9_]+)',
    '\] ([a-zA-Z0-9_]+)');

  procedure FormatExtension(var AStr: string);
  begin
    if not AStr.ToLower.EndsWith('.pas') then
      AStr := AStr + '.pas';
  end;

var
  LIndex: Integer;
begin
  for LIndex := 0 to Pred(Length(LIST_REGEx_UNIT_NAME)) do
  begin
    Result := ExtractValue(AStr, LIST_REGEx_UNIT_NAME[LIndex]);
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

function TStacktraceJCL.Get: TArray<TStacktrace>;
begin
  Result := FStackTrace; 
end;

end.
