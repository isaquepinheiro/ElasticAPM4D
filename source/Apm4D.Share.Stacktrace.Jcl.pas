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
    function ExtractValue(const AStr, ARegEX: string): string;
    function GetLine(const AStr: string): Integer;
    function GetUnitName(const AStr: string): string;
    function GetClassName(const AStr: string): string;
    function GetContextLine(const AStr: string): string;
    function GetStackList: TStringList;
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
  StackList: TStringList;
  Stacktrace: TStacktrace;
  Line: Integer;
  JclStackTrace: TStacktraceJCL;
  FrameCount: Integer;
begin
  FStackTrace := [];
  FrameCount := 0;
  JclStackTrace := TStacktraceJCL.Create;
  StackList := JclStackTrace.GetStackList;
  try
    for Line := 0 to Pred(StackList.Count) do
    begin
      if FrameCount >= MAX_FRAMES then
        Break; // Stop after collecting enough frames
        
      if not JclStackTrace.IsValidStacktrace(StackList.Strings[Line]) then
        Continue;

      Stacktrace := TStacktrace.Create;
      Stacktrace.lineno := JclStackTrace.GetLine(StackList.Strings[Line]);
      Stacktrace.module := JclStackTrace.GetClassName(StackList.Strings[Line]);
      Stacktrace.filename := JclStackTrace.GetUnitName(StackList.Strings[Line]);
      Stacktrace.Context_line := JclStackTrace.GetContextLine(StackList.Strings[Line]);

      if JclStackTrace.IsIgnoreUnit(Stacktrace.filename) then
      begin
        Stacktrace.Free;
        Continue;
      end;
      
      FStackTrace := FStackTrace + [Stacktrace];
      Inc(FrameCount);
    end;
  finally
    StackList.Free;
    JclStackTrace.Free;
  end;  
end;

function TStacktraceJCL.IsValidStacktrace(const AStr: string): Boolean;
begin
  Result := not ExtractValue(AStr, '(?<=\])(.*?)(?=\+)').IsEmpty;
end;

function TStacktraceJCL.ExtractValue(const AStr, ARegEX: string): string;
var
  LMath: TMatch;
begin
  LMath := TRegEx.Match(AStr, ARegEX);
  if LMath.Success and (LMath.Groups.Count > 0) then
    Exit(LMath.Groups.Item[Pred(LMath.Groups.Count)].Value);

  Result := '';
end;

function TStacktraceJCL.GetClassName(const AStr: string): string;
begin
  Result := ExtractValue(AStr, '(\T[a-zA-Z0-9_]+)');
end;

function TStacktraceJCL.GetContextLine(const AStr: string): string;
begin
  Result := ExtractValue(AStr, '(?<=\])(.*?)(?=\+)');
  if Pos('(', Result) > 0 then
    Result := Result + ')';
end;

function TStacktraceJCL.GetCulprit: string;
var
  Stack: TStacktrace;
  List: TArray<string>;
begin
  if Length(FStackTrace) = 0 then
    Exit('');
  Stack := FStackTrace[0];
  List := Stack.Context_line.Remove(Pos('(', Stack.Context_line) - 1).Split(['.']);
  Result := List[Length(List) - 1];
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
  StackInfo: TJclStackInfoList;
{$ENDIF}
{$ENDIF}
begin
  Result := TStringList.Create;
{$IFDEF MSWINDOWS}
{$IFDEF jcl}
  StackInfo := JclCreateStackList(True, 0, nil);
  try
    StackInfo.AddToStrings(Result, True, True, True, True);
  finally
    StackInfo.Free;
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
    if TPath.GetFileNameWithoutExtension(AStr) <> AStr then
      AStr := TPath.ChangeExtension(AStr, '.pas');
  end;

var
  I: Integer;
begin
  for I := 0 to Pred(Length(LIST_REGEx_UNIT_NAME)) do
  begin
    Result := ExtractValue(AStr, LIST_REGEx_UNIT_NAME[I]);
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
  Current: string;
begin
  for Current in Units do
  begin
    Result := AUnitName.ToLower.Trim.StartsWith(Current.ToLower);
    if Result then
      Exit;
  end;
end;

function TStacktraceJCL.Get: TArray<TStacktrace>;
begin
  Result := FStackTrace; 
end;

end.
