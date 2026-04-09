unit Test.Span;

interface

uses
  DUnitX.TestFramework, System.SysUtils, Apm4D.Span;

type
  [TestFixture]
  TTestSpan = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Should_Create_With_Hierarchy_Ids;
    
    [Test]
    procedure Should_Start_With_Name_And_Type;
    
    [Test]
    procedure Should_Auto_Set_Action_For_Database;
    
    [Test]
    procedure Should_Calculate_Duration_When_Ending;
    
    [Test]
    procedure Should_Pause_And_Unpause_Correctly;
  end;

implementation

{ TTestSpan }

procedure TTestSpan.Setup;
begin
end;

procedure TTestSpan.TearDown;
begin
end;

procedure TTestSpan.Should_Create_With_Hierarchy_Ids;
var
  LSpan: TSpan;
begin
  LSpan := TSpan.Create('trace_id_123', 'trans_id_123', 'parent_id_123');
  try
    Assert.IsNotEmpty(LSpan.Id, 'Span ID should be generated');
    Assert.AreEqual('trace_id_123', LSpan.Trace_id);
    Assert.AreEqual('trans_id_123', LSpan.Transaction_id);
    Assert.AreEqual('parent_id_123', LSpan.Parent_id);
  finally
    LSpan.Free;
  end;
end;

procedure TTestSpan.Should_Start_With_Name_And_Type;
var
  LSpan: TSpan;
begin
  LSpan := TSpan.Create('trace', 'trans', 'parent');
  try
    LSpan.Start('TestSpan', 'custom_type');
    Assert.AreEqual('TestSpan', LSpan.Name);
    Assert.AreEqual('custom_type', LSpan.&Type);
  finally
    LSpan.Free;
  end;
end;

procedure TTestSpan.Should_Auto_Set_Action_For_Database;
var
  LSpan: TSpan;
begin
  LSpan := TSpan.Create('trace', 'trans', 'parent');
  try
    LSpan.Start('DB Span', 'db');
    Assert.AreEqual('query', LSpan.Action, 'Action should be auto-set to query for db');
  finally
    LSpan.Free;
  end;
end;

procedure TTestSpan.Should_Calculate_Duration_When_Ending;
var
  LSpan: TSpan;
begin
  LSpan := TSpan.Create('trace', 'trans', 'parent');
  try
    LSpan.Start('TestSpan');
    Sleep(50);
    LSpan.ToEnd;
    Assert.IsTrue(LSpan.Duration >= 50, 'Duration should be at least the sleep time');
    Assert.AreEqual('success', LSpan.Outcome, 'Default outcome should be success');
  finally
    LSpan.Free;
  end;
end;

procedure TTestSpan.Should_Pause_And_Unpause_Correctly;
var
  LSpan: TSpan;
begin
  LSpan := TSpan.Create('trace', 'trans', 'parent');
  try
    LSpan.Start('TestSpan');
    Assert.IsFalse(LSpan.IsPaused, 'Should not start paused');
    
    LSpan.Pause;
    Assert.IsTrue(LSpan.IsPaused, 'Should be paused');
    
    LSpan.UnPause;
    Assert.IsFalse(LSpan.IsPaused, 'Should be unpaused');
  finally
    LSpan.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSpan);

end.
