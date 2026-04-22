unit Apm4D.Tests.Stacktrace;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.SysUtils,
  System.RegularExpressions,
  Apm4D.Share.Stacktrace,
  Apm4D.Share.Stacktrace.Jcl;

type
  // Test double to simulate JCL output without needing the JCL library active
  TTestStacktraceJCL = class(TStacktraceJCL)
  private
    FMockStrings: TStrings;
  public
    constructor Create(AMockStrings: TStrings);
    destructor Destroy; override;
    function GetStackList: TStringList; override;
    
    // Helper to call protected methods
    function CallExtractValue(const AStr, ARegEX: string): string;
    function CallGetLine(const AStr: string): Integer;
    function CallGetUnitName(const AStr: string): string;
    function CallGetClassName(const AStr: string): string;
    function CallGetFunctionName(const AStr: string): string;
    function CallIsIgnoreUnit(const AUnitName: string): Boolean;
  end;

  [TestFixture]
  TStacktraceTests = class
  public
    [Test]
    procedure Should_Parse_Standard_Jcl_Frame;
    [Test]
    procedure Should_Extract_Function_Name_From_Jcl_String;
    [Test]
    procedure Should_Ignore_Internal_Apm4D_Units;
    [Test]
    procedure Should_Handle_Malformed_Strings_Gracefully;
    [Test]
    procedure Should_Return_Correct_Culprit;
    [Test]
    procedure Should_Limit_Frames_To_Max_Frames;
  end;

implementation

{ TTestStacktraceJCL }

constructor TTestStacktraceJCL.Create(AMockStrings: TStrings);
begin
  FMockStrings := TStringList.Create;
  FMockStrings.Assign(AMockStrings);
  inherited Create;
end;

destructor TTestStacktraceJCL.Destroy;
begin
  FMockStrings.Free;
  inherited;
end;

function TTestStacktraceJCL.GetStackList: TStringList;
begin
  Result := TStringList.Create;
  Result.Assign(FMockStrings);
end;

function TTestStacktraceJCL.CallExtractValue(const AStr, ARegEX: string): string;
begin
  Result := ExtractValue(AStr, TRegEx.Create(ARegEX));
end;

function TTestStacktraceJCL.CallGetLine(const AStr: string): Integer;
begin
  Result := GetLine(AStr);
end;

function TTestStacktraceJCL.CallGetUnitName(const AStr: string): string;
begin
  Result := GetUnitName(AStr);
end;

function TTestStacktraceJCL.CallGetClassName(const AStr: string): string;
begin
  Result := GetClassName(AStr);
end;

function TTestStacktraceJCL.CallGetFunctionName(const AStr: string): string;
begin
  Result := GetFunctionName(AStr);
end;

function TTestStacktraceJCL.CallIsIgnoreUnit(const AUnitName: string): Boolean;
begin
  Result := IsIgnoreUnit(AUnitName);
end;

{ TStacktraceTests }

procedure TStacktraceTests.Should_Parse_Standard_Jcl_Frame;
var
  LTracer: TTestStacktraceJCL;
  LMock: TStringList;
  LFrame: TStacktrace;
begin
  LMock := TStringList.Create;
  try
    // Standard JCL format
    LMock.Add('[0040510D] MyUnit.TMyClass.MyMethod (Line 123, "MyUnit.pas" + 5) + 0');
    LTracer := TTestStacktraceJCL.Create(LMock);
    try
      Assert.AreEqual(1, Integer(Length(LTracer.Get)));
      LFrame := LTracer.Get[0];
      Assert.AreEqual(123, LFrame.lineno);
      Assert.AreEqual('MyUnit.pas', LFrame.filename);
      Assert.AreEqual('TMyClass', LFrame.module);
      Assert.AreEqual('MyUnit.TMyClass.MyMethod', LFrame.&function);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceTests.Should_Extract_Function_Name_From_Jcl_String;
var
  LTracer: TTestStacktraceJCL;
  LMock: TStringList;
  LSample: string;
begin
  LMock := TStringList.Create;
  LTracer := TTestStacktraceJCL.Create(LMock);
  try
    LSample := '[0040510D] Unit.Class.Method (Line 10, "File.pas")';
    Assert.AreEqual('Unit.Class.Method', LTracer.CallGetFunctionName(LSample));
    
    LSample := '[0040510D] GlobalFunction (Line 5, "File.pas")';
    Assert.AreEqual('GlobalFunction', LTracer.CallGetFunctionName(LSample));
  finally
    LTracer.Free;
    LMock.Free;
  end;
end;

procedure TStacktraceTests.Should_Ignore_Internal_Apm4D_Units;
var
  LTracer: TTestStacktraceJCL;
  LMock: TStringList;
begin
  LMock := TStringList.Create;
  LTracer := TTestStacktraceJCL.Create(LMock);
  try
    Assert.IsTrue(LTracer.CallIsIgnoreUnit('Apm4D.pas'));
    Assert.IsTrue(LTracer.CallIsIgnoreUnit('Apm4D.Share.Stacktrace.pas'));
    Assert.IsTrue(LTracer.CallIsIgnoreUnit('jcldebug.pas'));
    Assert.IsFalse(LTracer.CallIsIgnoreUnit('MyBusinessUnit.pas'));
  finally
    LTracer.Free;
    LMock.Free;
  end;
end;

procedure TStacktraceTests.Should_Handle_Malformed_Strings_Gracefully;
var
  LTracer: TTestStacktraceJCL;
  LMock: TStringList;
begin
  LMock := TStringList.Create;
  LTracer := TTestStacktraceJCL.Create(LMock);
  try
    // Should not crash and return defaults
    Assert.AreEqual(0, LTracer.CallGetLine('invalid string'));
    Assert.AreEqual('unknown.pas', LTracer.CallGetUnitName('invalid string'));
    Assert.AreEqual('', LTracer.CallGetClassName('invalid string'));
  finally
    LTracer.Free;
    LMock.Free;
  end;
end;

procedure TStacktraceTests.Should_Return_Correct_Culprit;
var
  LTracer: TTestStacktraceJCL;
  LMock: TStringList;
begin
  LMock := TStringList.Create;
  try
    LMock.Add('[001] Apm4D.Internal (Line 1, "Apm4D.pas")'); // Ignored
    LMock.Add('[002] MyUnit.MyMethod (Line 10, "MyUnit.pas")'); // First valid
    LTracer := TTestStacktraceJCL.Create(LMock);
    try
      Assert.AreEqual('MyUnit.MyMethod', LTracer.GetCulprit);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceTests.Should_Limit_Frames_To_Max_Frames;
var
  LTracer: TTestStacktraceJCL;
  LMock: TStringList;
  LIndex: Integer;
begin
  LMock := TStringList.Create;
  try
    for LIndex := 1 to 30 do
      LMock.Add(Format('[%d] Unit.Func (Line %d, "Unit.pas")', [LIndex, LIndex]));
      
    LTracer := TTestStacktraceJCL.Create(LMock);
    try
      Assert.AreEqual(15, Integer(Length(LTracer.Get)), 'Should limit to MAX_FRAMES (15)');
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TStacktraceTests);

end.
