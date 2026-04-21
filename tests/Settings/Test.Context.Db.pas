unit Test.Context.Db;

interface

uses
  DUnitX.TestFramework,
  Apm4D.Span.Context.Db;

type
  [TestFixture]
  TTestContextDb = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure Should_Create_From_Settings;
    
    [Test]
    procedure Should_Add_SQL_Simple;
    
    [Test]
    procedure Should_Add_SQL_Regex_Command;
    
    [Test]
    procedure Should_Add_SQL_Regex_Command_And_RowsAffected;
  end;

implementation

uses
  System.SysUtils,
  Apm4D.Settings;

{ TTestContextDb }

procedure TTestContextDb.Setup;
begin
  TApm4DSettings.ReleaseInstance;
  
  // Set up some known values in TApm4DSettings.Database
  TApm4DSettings.Database.Instance := 'test_instance';
  TApm4DSettings.Database.&Type := 'postgresql';
  TApm4DSettings.Database.User := 'test_user';
  TApm4DSettings.Database.Server := 'localhost:5432';
end;

procedure TTestContextDb.TearDown;
begin
  // Clean up global state
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestContextDb.Should_Create_From_Settings;
var
  LDbContext: TSpanContextDB;
begin
  LDbContext := TSpanContextDB.Create;
  try
    Assert.AreEqual('test_instance', LDbContext.Instance);
    Assert.AreEqual('postgresql', LDbContext.&Type);
    Assert.AreEqual('test_user', LDbContext.User);
    Assert.AreEqual('localhost:5432', LDbContext.Link);
  finally
    LDbContext.Free;
  end;
end;

procedure TTestContextDb.Should_Add_SQL_Simple;
var
  LDbContext: TSpanContextDB;
begin
  LDbContext := TSpanContextDB.Create;
  try
    LDbContext.AddSQL('SELECT * FROM users', 5);
    Assert.AreEqual('SELECT * FROM users', LDbContext.Statement);
    Assert.AreEqual(5, LDbContext.Rows_affected);
  finally
    LDbContext.Free;
  end;
end;

procedure TTestContextDb.Should_Add_SQL_Regex_Command;
var
  LDbContext: TSpanContextDB;
  LInput: string;
begin
  LDbContext := TSpanContextDB.Create;
  try
    // Input format matching the regex without RowsAffected
    LInput := '<< Close [Command="UPDATE users SET active = 1" ... ]';
    LDbContext.AddSQL(LInput, 0);
    Assert.AreEqual('UPDATE users SET active = 1', LDbContext.Statement);
    Assert.AreEqual(0, LDbContext.Rows_affected);
  finally
    LDbContext.Free;
  end;
end;

procedure TTestContextDb.Should_Add_SQL_Regex_Command_And_RowsAffected;
var
  LDbContext: TSpanContextDB;
  LInput: string;
begin
  LDbContext := TSpanContextDB.Create;
  try
    // Input format matching the regex with RowsAffected
    LInput := '<< Close [Command="DELETE FROM old_logs" ... RowsAffected=12 ...]';
    LDbContext.AddSQL(LInput, 0);
    Assert.AreEqual('DELETE FROM old_logs', LDbContext.Statement);
    Assert.AreEqual(12, LDbContext.Rows_affected);
  finally
    LDbContext.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestContextDb);

end.
