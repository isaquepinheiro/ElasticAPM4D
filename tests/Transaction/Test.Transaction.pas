unit Test.Transaction;

interface

uses
  DUnitX.TestFramework, System.SysUtils, Apm4D.Transaction, Apm4D.Share.Types;

type
  [TestFixture]
  TTestTransaction = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Should_Create_With_Valid_Ids;
    
    [Test]
    procedure Should_Start_With_Name_And_Type;
    
    [Test]
    procedure Should_Set_Outcome_And_Result;
    
    [Test]
    procedure Should_Pause_And_Unpause_Correctly;
    
    [Test]
    procedure Should_Calculate_Duration_When_Ending;
  end;

implementation

{ TTestTransaction }

procedure TTestTransaction.Setup;
begin
end;

procedure TTestTransaction.TearDown;
begin
end;

procedure TTestTransaction.Should_Create_With_Valid_Ids;
var
  LTrans: TTransaction;
begin
  LTrans := TTransaction.Create;
  try
    Assert.IsNotEmpty(LTrans.id, 'Transaction ID should be generated');
    Assert.IsNotEmpty(LTrans.Trace_id, 'Trace ID should be generated');
  finally
    LTrans.Free;
  end;
end;

procedure TTestTransaction.Should_Start_With_Name_And_Type;
var
  LTrans: TTransaction;
begin
  LTrans := TTransaction.Create;
  try
    LTrans.Start('TestName', 'TestType');
    Assert.AreEqual('TestName', LTrans.Name);
    Assert.AreEqual('TestType', LTrans.&type);
    Assert.IsTrue(LTrans.Timestamp > 0, 'Timestamp should be set');
  finally
    LTrans.Free;
  end;
end;

procedure TTestTransaction.Should_Set_Outcome_And_Result;
var
  LTrans: TTransaction;
begin
  LTrans := TTransaction.Create;
  try
    LTrans.Start('TestName');
    LTrans.ToEnd(failure); // Explicit outcome
    
    Assert.AreEqual('failure', LTrans.Outcome);
    Assert.AreEqual('error', LTrans.&result);
  finally
    LTrans.Free;
  end;
end;

procedure TTestTransaction.Should_Pause_And_Unpause_Correctly;
var
  LTrans: TTransaction;
begin
  LTrans := TTransaction.Create;
  try
    LTrans.Start('TestName');
    
    Assert.IsFalse(LTrans.IsPaused, 'Should not start paused');
    
    LTrans.Pause;
    Assert.IsTrue(LTrans.IsPaused, 'Should be paused');
    
    Sleep(10); // Small delay
    LTrans.UnPause;
    
    Assert.IsFalse(LTrans.IsPaused, 'Should be unpaused');
    Assert.IsTrue(LTrans.GetPausedDuration >= 0, 'Paused duration should be recorded');
  finally
    LTrans.Free;
  end;
end;

procedure TTestTransaction.Should_Calculate_Duration_When_Ending;
var
  LTrans: TTransaction;
begin
  LTrans := TTransaction.Create;
  try
    LTrans.Start('TestName');
    Sleep(50); // Ensure some duration
    LTrans.ToEnd;
    
    Assert.IsTrue(LTrans.Duration >= 50, 'Duration should be at least the sleep time');
    Assert.AreEqual('success', LTrans.Outcome, 'Default outcome should be success');
  finally
    LTrans.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTransaction);

end.
