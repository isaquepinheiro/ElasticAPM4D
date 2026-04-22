unit Test.Error;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Apm4D.Error,
  Apm4D.Settings,
  Apm4D.Share.Stacktrace;

type
  // Test double que produz frames e culprit previsveis e deterministas
  TTestStackTracer = class(TStackTracer)
  public
    constructor Create; override;
    function GetCulprit: string; override;
  end;

  [TestFixture]
  TTestError = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Should_Create_With_Valid_Ids;

    [Test]
    procedure Should_Set_Exception_Message_And_Type;

    [Test]
    procedure Should_Have_Empty_Stacktrace_Without_StackTracer;

    [Test]
    procedure Should_Have_Culprit_When_StackTracer_Is_Registered;

    [Test]
    procedure Should_Have_Frames_When_StackTracer_Is_Registered;
  end;

implementation

{ TTestStackTracer }

constructor TTestStackTracer.Create;
var
  LFrame: TStacktrace;
begin
  inherited Create;
  LFrame := TStacktrace.Create;
  LFrame.Filename := 'MyUnit.pas';
  LFrame.Lineno := 42;
  LFrame.Context_line := 'TMyClass.DoSomething';
  LFrame.Module := 'TMyClass';
  FStackTrace := [LFrame];
end;

function TTestStackTracer.GetCulprit: string;
begin
  Result := 'TMyClass.DoSomething';
end;

{ TTestError }

procedure TTestError.Setup;
begin
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestError.TearDown;
begin
  TApm4DSettings.Deactivate;
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestError.Should_Create_With_Valid_Ids;
var
  LError: TError;
begin
  LError := TError.Create('trace123', 'trans123', 'parent123');
  try
    Assert.IsNotEmpty(LError.Id, 'Error ID should be generated');
    Assert.AreEqual('trace123', LError.Trace_id);
    Assert.AreEqual('trans123', LError.Transaction_id);
    Assert.AreEqual('parent123', LError.Parent_id);
    Assert.IsTrue(LError.Timestamp > 0, 'Timestamp should be set on creation');
  finally
    LError.Free;
  end;
end;

procedure TTestError.Should_Set_Exception_Message_And_Type;
var
  LError: TError;
begin
  LError := TError.Create('trace', 'trans', 'parent');
  try
    LError.Exception.&Message := 'Division by zero';
    LError.Exception.&Type := 'EZeroDivide';

    Assert.AreEqual('Division by zero', LError.Exception.&Message);
    Assert.AreEqual('EZeroDivide', LError.Exception.&Type);
  finally
    LError.Free;
  end;
end;

procedure TTestError.Should_Have_Empty_Stacktrace_Without_StackTracer;
var
  LError: TError;
begin
  // Sem StackTracer registrado: culprit e frames devem estar ausentes
  LError := TError.Create('trace', 'trans', 'parent');
  try
    Assert.AreEqual('', LError.Culprit,
      'Culprit must be empty when no StackTracer is registered');
    Assert.AreEqual(0, Integer(Length(LError.Exception.Stacktrace)),
      'Stacktrace must be empty when no StackTracer is registered');
  finally
    LError.Free;
  end;
end;

procedure TTestError.Should_Have_Culprit_When_StackTracer_Is_Registered;
var
  LError: TError;
begin
  TApm4DSettings.AddStackTracer(TTestStackTracer);
  LError := TError.Create('trace', 'trans', 'parent');
  try
    Assert.AreEqual('TMyClass.DoSomething', LError.Culprit,
      'Culprit must be populated from StackTracer when one is registered');
  finally
    LError.Free;
  end;
end;

procedure TTestError.Should_Have_Frames_When_StackTracer_Is_Registered;
var
  LError: TError;
  LFrame: TStacktrace;
begin
  TApm4DSettings.AddStackTracer(TTestStackTracer);
  LError := TError.Create('trace', 'trans', 'parent');
  try
    Assert.AreEqual(1, Integer(Length(LError.Exception.Stacktrace)),
      'Stacktrace must contain exactly one frame from the test tracer');
    LFrame := LError.Exception.Stacktrace[0];
    Assert.AreEqual('MyUnit.pas', LFrame.Filename,
      'Frame filename must match the value returned by the test tracer');
    Assert.AreEqual(42, LFrame.Lineno,
      'Frame line number must match the value returned by the test tracer');
    Assert.AreEqual('TMyClass.DoSomething', LFrame.Context_line,
      'Frame context line must match the value returned by the test tracer');
  finally
    LError.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestError);

end.
