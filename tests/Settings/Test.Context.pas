unit Test.Context;

interface

uses
  DUnitX.TestFramework,
  Apm4D.Share.Context;

type
  [TestFixture]
  TTestContext = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure Should_Initialize_User_And_Service_On_Create;
    
    [Test]
    procedure Should_Add_Request_Correctly;
    
    [Test]
    procedure Should_Add_Response_Correctly;
    
    [Test]
    procedure Should_Add_Message_Correctly;
    
    [Test]
    procedure Should_Add_Page_Without_Errors;
  end;

implementation

uses
  System.SysUtils;

{ TTestContext }

procedure TTestContext.Setup;
begin
end;

procedure TTestContext.TearDown;
begin
end;

procedure TTestContext.Should_Initialize_User_And_Service_On_Create;
var
  LContext: TContext;
begin
  LContext := TContext.Create;
  try
    Assert.IsNotNull(LContext.User, 'User should be created in constructor');
    Assert.IsNotNull(LContext.Service, 'Service should be created in constructor');
    
    Assert.IsNull(LContext.Request, 'Request should be null initially');
    Assert.IsNull(LContext.Response, 'Response should be null initially');
    Assert.IsNull(LContext.Message, 'Message should be null initially');
  finally
    LContext.Free;
  end;
end;

procedure TTestContext.Should_Add_Request_Correctly;
var
  LContext: TContext;
begin
  LContext := TContext.Create;
  try
    LContext.AddRequest('GET');
    Assert.IsNotNull(LContext.Request, 'Request should not be null after AddRequest');
    Assert.AreEqual('GET', LContext.Request.Method);
  finally
    LContext.Free;
  end;
end;

procedure TTestContext.Should_Add_Response_Correctly;
var
  LContext: TContext;
begin
  LContext := TContext.Create;
  try
    LContext.AddResponse(200);
    Assert.IsNotNull(LContext.Response, 'Response should not be null after AddResponse');
  finally
    LContext.Free;
  end;
end;

procedure TTestContext.Should_Add_Message_Correctly;
var
  LContext: TContext;
begin
  LContext := TContext.Create;
  try
    LContext.AddMessage('queue_name', 'body content');
    Assert.IsNotNull(LContext.Message, 'Message should not be null after AddMessage');
  finally
    LContext.Free;
  end;
end;

procedure TTestContext.Should_Add_Page_Without_Errors;
var
  LContext: TContext;
begin
  LContext := TContext.Create;
  try
    LContext.AddPage('http://referer.com', 'http://url.com');
    Assert.Pass('AddPage executed successfully without Access Violation.');
  finally
    LContext.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestContext);

end.
