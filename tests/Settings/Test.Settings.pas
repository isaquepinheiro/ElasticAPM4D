unit Test.Settings;

interface

uses
  DUnitX.TestFramework,
  Apm4D.Settings;

type
  [TestFixture]
  TTestSettings = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure Should_Return_Application_Defaults;
    
    [Test]
    procedure Should_Return_Elastic_Defaults;
    
    [Test]
    procedure Should_Configure_Application_Correctly;
    
    [Test]
    procedure Should_Configure_User_Correctly;
    
    [Test]
    procedure Should_Configure_Database_Correctly;
  end;

implementation

uses
  System.SysUtils;

{ TTestSettings }

procedure TTestSettings.Setup;
begin
  // Ensures clean state before test
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestSettings.TearDown;
begin
  // Clean up global state
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestSettings.Should_Return_Application_Defaults;
begin
  Assert.IsNotEmpty(TApm4DSettings.Application.Name, 'Application Name should not be empty');
  Assert.AreEqual('development', TApm4DSettings.Application.Environment, 'Default environment should be development');
end;

procedure TTestSettings.Should_Return_Elastic_Defaults;
begin
  Assert.AreEqual('http://127.0.0.1:8200/intake/v2/events', TApm4DSettings.Elastic.Url, 'Default URL should be http://127.0.0.1:8200/intake/v2/events');
  Assert.AreEqual(60000, TApm4DSettings.Elastic.UpdateTime, 'Default UpdateTime should be 60000');
  Assert.AreEqual(60, TApm4DSettings.Elastic.MaxJsonPerThread, 'Default MaxJsonPerThread should be 60');
end;

procedure TTestSettings.Should_Configure_Application_Correctly;
begin
  TApm4DSettings.Application.Name := 'TestApp';
  TApm4DSettings.Application.Version := '2.0';
  TApm4DSettings.Application.Environment := 'production';
  
  Assert.AreEqual('TestApp', TApm4DSettings.Application.Name);
  Assert.AreEqual('2.0', TApm4DSettings.Application.Version);
  Assert.AreEqual('production', TApm4DSettings.Application.Environment);
end;

procedure TTestSettings.Should_Configure_User_Correctly;
begin
  Assert.IsNotNull(TApm4DSettings.User);
  
  TApm4DSettings.User.Id := '12345';
  TApm4DSettings.User.Name := 'John Doe';
  TApm4DSettings.User.Email := 'john.doe@domain.com';
  
  Assert.AreEqual('12345', TApm4DSettings.User.Id);
  Assert.AreEqual('John Doe', TApm4DSettings.User.Name);
  Assert.AreEqual('john.doe@domain.com', TApm4DSettings.User.Email);
end;

procedure TTestSettings.Should_Configure_Database_Correctly;
begin
  Assert.IsNotNull(TApm4DSettings.Database);
  
  TApm4DSettings.Database.&Type := 'mysql';
  TApm4DSettings.Database.User := 'root';
  TApm4DSettings.Database.Instance := 'main_db';
  TApm4DSettings.Database.Server := 'localhost';
  
  Assert.AreEqual('mysql', TApm4DSettings.Database.&Type);
  Assert.AreEqual('root', TApm4DSettings.Database.User);
  Assert.AreEqual('main_db', TApm4DSettings.Database.Instance);
  Assert.AreEqual('localhost', TApm4DSettings.Database.Server);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSettings);

end.
