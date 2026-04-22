unit Test.StacktraceProviders;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  System.SysUtils,
  Apm4D.Settings,
  Apm4D.Share.Types,
  Apm4D.Share.Stacktrace,
  Apm4D.Share.Stacktrace.MadExcept,
  Apm4D.Share.Stacktrace.EurekaLog;

type
  // Test doubles to simulate providers without needing the libraries
  TTestMadExcept = class(TStacktraceMadExcept)
  private
    FMockStrings: TStrings;
  protected
    function GetStackList: TStringList; override;
  public
    constructor Create(const AMockStrings: TStrings);
    destructor Destroy; override;
  end;

  TTestEurekaLog = class(TStacktraceEurekaLog)
  private
    FMockStrings: TStrings;
  protected
    function GetStackList: TStringList; override;
  public
    constructor Create(const AMockStrings: TStrings);
    destructor Destroy; override;
  end;

  [TestFixture]
  TStacktraceProvidersTests = class
  public
    [Setup]
    procedure Setup;
    [Teardown]
    procedure Teardown;

    [Test]
    procedure Should_Set_And_Get_Provider_Property;
    [Test]
    procedure Should_Return_Nil_When_Provider_Is_None;
    [Test]
    procedure Should_Parse_MadExcept_Frames;
    [Test]
    procedure Should_Parse_EurekaLog_Frames;
    [Test]
    procedure Should_Respect_Max_Frames_In_New_Providers;
  end;

implementation

{ TTestMadExcept }

constructor TTestMadExcept.Create(const AMockStrings: TStrings);
begin
  FMockStrings := TStringList.Create;
  FMockStrings.Assign(AMockStrings);
  inherited Create;
end;

destructor TTestMadExcept.Destroy;
begin
  FMockStrings.Free;
  inherited;
end;

function TTestMadExcept.GetStackList: TStringList;
begin
  Result := TStringList.Create;
  Result.Assign(FMockStrings);
end;

{ TTestEurekaLog }

constructor TTestEurekaLog.Create(const AMockStrings: TStrings);
begin
  FMockStrings := TStringList.Create;
  FMockStrings.Assign(AMockStrings);
  inherited Create;
end;

destructor TTestEurekaLog.Destroy;
begin
  FMockStrings.Free;
  inherited;
end;

function TTestEurekaLog.GetStackList: TStringList;
begin
  Result := TStringList.Create;
  Result.Assign(FMockStrings);
end;

{ TStacktraceProvidersTests }

procedure TStacktraceProvidersTests.Setup;
begin
  TApm4DSettings.SetStacktraceProvider(spAutomatic);
end;

procedure TStacktraceProvidersTests.Teardown;
begin
  TApm4DSettings.ReleaseInstance;
end;

procedure TStacktraceProvidersTests.Should_Set_And_Get_Provider_Property;
begin
  TApm4DSettings.SetStacktraceProvider(spMadExcept);
  Assert.AreEqual(spMadExcept, TApm4DSettings.StacktraceProvider);
  
  TApm4DSettings.SetStacktraceProvider(spEurekaLog);
  Assert.AreEqual(spEurekaLog, TApm4DSettings.StacktraceProvider);
end;

procedure TStacktraceProvidersTests.Should_Return_Nil_When_Provider_Is_None;
var
  LTracer: TStackTracer;
begin
  TApm4DSettings.SetStacktraceProvider(spNone);
  LTracer := TApm4DSettings.CreateStackTracer;
  try
    Assert.IsNull(LTracer);
  finally
    LTracer.Free;
  end;
end;

procedure TStacktraceProvidersTests.Should_Parse_MadExcept_Frames;
var
  LTracer: TTestMadExcept;
  LMock: TStringList;
  LFrame: TStacktrace;
begin
  LMock := TStringList.Create;
  try
    // Mock MadExcept format: address +offset module unit line function
    LMock.Add('004bd967 +057 MyApp.exe Unit1.pas 32 TForm1.Button1Click');
    LTracer := TTestMadExcept.Create(LMock);
    try
      Assert.AreEqual(1, Integer(Length(LTracer.Get)));
      LFrame := LTracer.Get[0];
      Assert.AreEqual(32, LFrame.lineno);
      Assert.AreEqual('Unit1.pas', LFrame.filename);
      Assert.AreEqual('TForm1.Button1Click', LFrame.&function);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceProvidersTests.Should_Parse_EurekaLog_Frames;
var
  LTracer: TTestEurekaLog;
  LMock: TStringList;
  LFrame: TStacktrace;
begin
  LMock := TStringList.Create;
  try
    // Mock EurekaLog format
    LMock.Add('Unit1.pas 10 TForm1.ButtonClick line 10');
    LTracer := TTestEurekaLog.Create(LMock);
    try
      Assert.AreEqual(1, Integer(Length(LTracer.Get)));
      LFrame := LTracer.Get[0];
      Assert.AreEqual(10, LFrame.lineno);
      Assert.AreEqual('Unit1.pas', LFrame.filename);
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

procedure TStacktraceProvidersTests.Should_Respect_Max_Frames_In_New_Providers;
var
  LTracer: TTestMadExcept;
  LMock: TStringList;
  LIndex: Integer;
begin
  LMock := TStringList.Create;
  try
    for LIndex := 1 to 30 do
      LMock.Add(Format('00400000 +000 App.exe Unit.pas %d Func', [LIndex]));
      
    LTracer := TTestMadExcept.Create(LMock);
    try
      Assert.AreEqual(15, Integer(Length(LTracer.Get)), 'MadExcept should limit to 15 frames');
    finally
      LTracer.Free;
    end;
  finally
    LMock.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TStacktraceProvidersTests);

end.
