{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.SendThread.Test;

interface

uses
  DUnitX.TestFramework,
  Apm4D.SendThread,
  Apm4D.HttpClient.Mock,
  Apm4D.Share.Types;

type
  [TestFixture]
  TSendThreadTest = class
  private
    FMock: TApm4DHttpClientMock;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNormalFlow;
    [Test]
    procedure TestRetryOn429;
    [Test]
    procedure TestTerminateOn500;
  end;

implementation

uses
  Apm4D.Settings, System.SysUtils, System.Classes, Apm4D.HttpClient.Indy;

var
  GMock: IApm4DHttpClient;

function MockFactory: IApm4DHttpClient;
begin
  Result := GMock;
end;

{ TSendThreadTest }

procedure TSendThreadTest.Setup;
begin
  FMock := TApm4DHttpClientMock.Create;
  GMock := FMock;
  TApm4DSettings.SetHttpClientFactory(MockFactory);
end;

procedure TSendThreadTest.TearDown;
begin
  TApm4DSettings.SetHttpClientFactory(TApm4DIdHttpClientFactory);
end;

procedure TSendThreadTest.TestNormalFlow;
var
  LThread: TSendThread;
  LData: TDataSend;
begin
  LThread := TSendThread.Create('http://localhost:8200', 'secret');
  try
    LData.Json := '{"metadata":{}}';
    LData.Header := 'trace-1';
    LThread.InternalList.Add(LData);
    
    LThread.Start;
    LThread.WaitFor;
    
    Assert.AreEqual<Integer>(1, FMock.Calls.Count);
    Assert.AreEqual<Integer>(0, LThread.TotalErrors);
  finally
    LThread.Free;
  end;
end;

procedure TSendThreadTest.TestRetryOn429;
var
  LThread: TSendThread;
  LData: TDataSend;
begin
  FMock.QueueResponseCode(429);
  FMock.QueueResponseCode(200);
  
  LThread := TSendThread.Create('http://localhost:8200', 'secret');
  try
    LData.Json := '{"metadata":{}}';
    LData.Header := 'trace-1';
    LThread.InternalList.Add(LData);
    
    LThread.Start;
    LThread.WaitFor;
    
    Assert.AreEqual<Integer>(2, FMock.Calls.Count);
    Assert.AreEqual<Integer>(1, LThread.TotalErrors);
  finally
    LThread.Free;
  end;
end;

procedure TSendThreadTest.TestTerminateOn500;
var
  LThread: TSendThread;
  LData: TDataSend;
begin
  FMock.SetResponseCode(500);
  
  LThread := TSendThread.Create('http://localhost:8200', 'secret');
  try
    LData.Json := '{"metadata":{}}';
    LData.Header := 'trace-1';
    LThread.InternalList.Add(LData);
    
    LThread.Start;
    LThread.WaitFor;
    
    Assert.AreEqual<Integer>(1, FMock.Calls.Count);
    Assert.AreEqual<Integer>(1, LThread.TotalErrors);
    Assert.AreEqual<Integer>(1, LThread.ConnectionError);
  finally
    LThread.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSendThreadTest);

end.
