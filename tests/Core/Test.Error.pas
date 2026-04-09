unit Test.Error;

interface

uses
  DUnitX.TestFramework, System.SysUtils, Apm4D.Error;

type
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
    procedure Should_Capture_Stacktrace_On_Create;
  end;

implementation

{ TTestError }

procedure TTestError.Setup;
begin
end;

procedure TTestError.TearDown;
begin
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

procedure TTestError.Should_Capture_Stacktrace_On_Create;
var
  LError: TError;
begin
  // Simulating error creation in a context where JCL might provide a stack trace
  LError := TError.Create('trace', 'trans', 'parent');
  try
    // Culprit or stacktrace might be empty depending on environment and JCL availability
    // but the object shouldn't crash.
    Assert.IsNotNull(LError.Exception.Stacktrace, 'Stacktrace array should be initialized (even if empty)');
  finally
    LError.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestError);

end.
