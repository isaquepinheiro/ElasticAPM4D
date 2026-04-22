unit Apm4D.Tests.Stacktrace.Hardening;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.SysUtils,
  Apm4D.Share.Types,
  Apm4D.Share.Stacktrace,
  Apm4D.Share.Stacktrace.Jcl,
  Apm4D.Share.Stacktrace.MadExcept,
  Apm4D.Share.Stacktrace.EurekaLog;

type
  { Test Doubles }

  TTestJclHardening = class(TStacktraceJCL)
  private
    FMockStrings: TStrings;
  protected
    function GetStackList: TStringList; override;
  public
    constructor Create(const AMockStrings: TStrings);
    destructor Destroy; override;
  end;

  TTestMadExceptHardening = class(TStacktraceMadExcept)
  private
    FMockStrings: TStrings;
  protected
    function GetStackList: TStringList; override;
  public
    constructor Create(const AMockStrings: TStrings);
    destructor Destroy; override;
  end;

  TTestEurekaLogHardening = class(TStacktraceEurekaLog)
  private
    FMockStrings: TStrings;
  protected
    function GetStackList: TStringList; override;
  public
    constructor Create(const AMockStrings: TStrings);
    destructor Destroy; override;
  end;

  [TestFixture]
  TStacktraceHardeningTests = class
  public
    [Test]
    procedure Should_Correct_Identify_Culprit_With_Mixed_Frames;
    [Test]
    procedure Should_Handle_Deeply_Nested_Exception_Stacks;
    [Test]
    procedure Should_Not_Crash_On_Random_Garbage_Input;
    [Test]
    procedure Should_Correct_Parse_Complex_MadExcept_With_Offsets;
    [Test]
    procedure Should_Respect_Max_Frames_Across_All_Providers;
    [Test]
    procedure Should_Handle_Malformed_EurekaLog_Frames;
    [Test]
    procedure Should_Filter_Internal_Apm4D_Units;
  end;

implementation

{ TTestJclHardening }

constructor TTestJclHardening.Create(const AMockStrings: TStrings);
begin
  FMockStrings := TStringList.Create;
  FMockStrings.Assign(AMockStrings);
  inherited Create;
end;

destructor TTestJclHardening.Destroy;
begin
  FMockStrings.Free;
  inherited;
end;

function TTestJclHardening.GetStackList: TStringList;
begin
  Result := TStringList.Create;
  Result.Assign(FMockStrings);
end;

{ TTestMadExceptHardening }

constructor TTestMadExceptHardening.Create(const AMockStrings: TStrings);
begin
  FMockStrings := TStringList.Create;
  FMockStrings.Assign(AMockStrings);
  inherited Create;
end;

destructor TTestMadExceptHardening.Destroy;
begin
  FMockStrings.Free;
  inherited;
end;

function TTestMadExceptHardening.GetStackList: TStringList;
begin
  Result := TStringList.Create;
  Result.Assign(FMockStrings);
end;

{ TTestEurekaLogHardening }

constructor TTestEurekaLogHardening.Create(const AMockStrings: TStrings);
begin
  FMockStrings := TStringList.Create;
  FMockStrings.Assign(AMockStrings);
  inherited Create;
end;

destructor TTestEurekaLogHardening.Destroy;
begin
  FMockStrings.Free;
  inherited;
end;

function TTestEurekaLogHardening.GetStackList: TStringList;
begin
  Result := TStringList.Create;
  Result.Assign(FMockStrings);
end;

{ TStacktraceHardeningTests }

procedure TStacktraceHardeningTests.Should_Correct_Identify_Culprit_With_Mixed_Frames;
var
  LMock: TStringList;
  LTracer: TTestJclHardening;
begin
  LMock := TStringList.Create;
  try
    // Frames are added from top to bottom (most recent first)
    LMock.Add('[00401234] Apm4D.TApm4D.CaptureError (Line 100)');
    LMock.Add('[00405678] Apm4D.Share.Stacktrace.TStacktrace.Create (Line 50)');
    LMock.Add('[00509ABC] MyBusinessLogic.TMyService.ExecuteTask (Line 42)');
    LMock.Add('[0060DEF0] Vcl.Forms.TCustomForm.Show (Line 1000)');
    
    LTracer := TTestJclHardening.Create(LMock);
    try
      // Culprit should be the first NON-Apm4D unit
      // Note: JCL provider filters out Apm4D units during construction
      Assert.AreEqual('MyBusinessLogic.TMyService.ExecuteTask', LTracer.GetCulprit);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceHardeningTests.Should_Handle_Deeply_Nested_Exception_Stacks;
var
  LMock: TStringList;
  LTracer: TTestMadExceptHardening;
  LFor: Integer;
begin
  LMock := TStringList.Create;
  try
    for LFor := 1 to 50 do
      LMock.Add(Format('004000%d MyApp.exe MyUnit.pas %d MyDeepFunction%d', [LFor, LFor, LFor]));
      
    LTracer := TTestMadExceptHardening.Create(LMock);
    try
      // Should limit to MAX_FRAMES (15) and not crash
      Assert.AreEqual(15, Length(LTracer.Get));
      Assert.AreEqual('MyDeepFunction1', LTracer.GetCulprit);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceHardeningTests.Should_Not_Crash_On_Random_Garbage_Input;
var
  LMock: TStringList;
  LTracer: TTestJclHardening;
begin
  LMock := TStringList.Create;
  try
    LMock.Add('This is not a stacktrace line');
    LMock.Add('!!! @@@ ### $$$');
    LMock.Add('');
    LMock.Add('00401234 [Without brackets]');
    
    LTracer := TTestJclHardening.Create(LMock);
    try
      // Should result in empty stack but not crash
      Assert.AreEqual(0, Length(LTracer.Get));
      Assert.AreEqual('unknown', LTracer.GetCulprit);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceHardeningTests.Should_Correct_Parse_Complex_MadExcept_With_Offsets;
var
  LMock: TStringList;
  LTracer: TTestMadExceptHardening;
  LStack: TArray<TStacktrace>;
begin
  LMock := TStringList.Create;
  try
    // Complex MadExcept format with offsets and class.method
    LMock.Add('004bd967 +057 MyApp.exe Unit1.pas 32 TForm1.Button1Click');
    LMock.Add('004bca12 +012 MyApp.exe Business.pas 150 TProcessor.ProcessData');
    
    LTracer := TTestMadExceptHardening.Create(LMock);
    try
      LStack := LTracer.Get;
      Assert.AreEqual(2, Length(LStack));
      
      Assert.AreEqual('Unit1.pas', LStack[0].filename);
      Assert.AreEqual(32, LStack[0].lineno);
      Assert.AreEqual('TForm1.Button1Click', LStack[0].&function);
      
      Assert.AreEqual('Business.pas', LStack[1].filename);
      Assert.AreEqual(150, LStack[1].lineno);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceHardeningTests.Should_Respect_Max_Frames_Across_All_Providers;
var
  LMock: TStringList;
  LJcl: TTestJclHardening;
  LMad: TTestMadExceptHardening;
  LEur: TTestEurekaLogHardening;
  LFor: Integer;
begin
  LMock := TStringList.Create;
  try
    for LFor := 1 to 20 do
      LMock.Add(Format('[00400000] Unit%d.pas (Line %d) Func%d', [LFor, LFor, LFor]));
      
    LJcl := TTestJclHardening.Create(LMock);
    try
      Assert.AreEqual(15, Length(LJcl.Get), 'JCL limit');
    finally
      LJcl.Free;
    end;

    LMock.Clear;
    for LFor := 1 to 20 do
      LMock.Add(Format('00400000 MyApp.exe Unit%d.pas %d Func%d', [LFor, LFor, LFor]));
      
    LMad := TTestMadExceptHardening.Create(LMock);
    try
      Assert.AreEqual(15, Length(LMad.Get), 'MadExcept limit');
    finally
      LMad.Free;
    end;

    LMock.Clear;
    for LFor := 1 to 20 do
      LMock.Add(Format('Unit%d.pas %d Func%d line %d', [LFor, LFor, LFor, LFor]));
      
    LEur := TTestEurekaLogHardening.Create(LMock);
    try
      Assert.AreEqual(15, Length(LEur.Get), 'EurekaLog limit');
    finally
      LEur.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceHardeningTests.Should_Handle_Malformed_EurekaLog_Frames;
var
  LMock: TStringList;
  LTracer: TTestEurekaLogHardening;
begin
  LMock := TStringList.Create;
  try
    LMock.Add('UnitWithoutPas 10 FunctionWithoutClass line 10');
    LMock.Add('OnlyUnit.pas');
    LMock.Add('100 line 100');
    
    LTracer := TTestEurekaLogHardening.Create(LMock);
    try
      // Even with malformed strings, it should try its best or skip safely
      // In current implementation, EurekaLog needs .pas or 'line' to find stuff
      Assert.IsTrue(Length(LTracer.Get) > 0);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceHardeningTests.Should_Filter_Internal_Apm4D_Units;
var
  LMock: TStringList;
  LTracer: TTestJclHardening;
begin
  LMock := TStringList.Create;
  try
    LMock.Add('[00400000] Apm4D.TApm4D.Test (Line 1)');
    LMock.Add('[00400000] Apm4D.Settings.TApm4DSettings.Test (Line 1)');
    LMock.Add('[00400000] Apm4D.Share.Stacktrace.TTracer.Test (Line 1)');
    LMock.Add('[00400000] UserUnit.TUser.Test (Line 10)');
    
    LTracer := TTestJclHardening.Create(LMock);
    try
      // All Apm4D.* units should be filtered out
      Assert.AreEqual(1, Length(LTracer.Get));
      Assert.AreEqual('UserUnit.TUser.Test', LTracer.Get[0].&function);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TStacktraceHardeningTests);

end.
