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
    procedure TestRetryOn500;
    [Test]
    procedure TestMaxRetriesExceeded;
    [Test]
    procedure TestImmediateTerminate;
  end;

implementation

uses
  Apm4D.Settings, System.SysUtils, System.Classes, Apm4D.HttpClient.Indy, System.Diagnostics;

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
  // Speed up tests by reducing delays
  TApm4DSettings.Elastic.InitialRetryDelay := 10;
  TApm4DSettings.Elastic.MaxRetryDelay := 100;
  TApm4DSettings.Elastic.MaxRetries := 3;
end;

procedure TSendThreadTest.TearDown;
begin
  TApm4DSettings.SetHttpClientFactory(TApm4DIdHttpClientFactory);
  TApm4DSettings.ReleaseInstance;
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
  FMock.QueueResponseCode(429);
  FMock.QueueResponseCode(200);
  
  LThread := TSendThread.Create('http://localhost:8200', 'secret');
  try
    LData.Json := '{"metadata":{}}';
    LData.Header := 'trace-1';
    LThread.InternalList.Add(LData);
    
    LThread.Start;
    LThread.WaitFor;
    
    Assert.AreEqual<Integer>(3, FMock.Calls.Count);
    Assert.AreEqual<Integer>(2, LThread.TotalErrors);
    Assert.AreEqual<Integer>(0, LThread.ConnectionError);
  finally
    LThread.Free;
  end;
end;

procedure TSendThreadTest.TestRetryOn500;
var
  LThread: TSendThread;
  LData: TDataSend;
begin
  FMock.QueueResponseCode(500);
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

procedure TSendThreadTest.TestMaxRetriesExceeded;
var
  LThread: TSendThread;
  LData: TDataSend;
begin
  FMock.SetResponseCode(503);
  
  LThread := TSendThread.Create('http://localhost:8200', 'secret');
  try
    LData.Json := '{"metadata":{}}';
    LData.Header := 'trace-1';
    LThread.InternalList.Add(LData);
    
    LThread.Start;
    LThread.WaitFor;
    
    // Initial call + 3 retries = 4 calls
    Assert.AreEqual<Integer>(4, FMock.Calls.Count);
    Assert.AreEqual<Integer>(4, LThread.TotalErrors);
    Assert.AreEqual<Integer>(1, LThread.ConnectionError);
  finally
    LThread.Free;
  end;
end;

procedure TSendThreadTest.TestImmediateTerminate;
var
  LThread: TSendThread;
  LData: TDataSend;
  LStopwatch: TStopwatch;
begin
  FMock.SetResponseCode(429);
  // Increase delay for this test to prove interruptible wait
  TApm4DSettings.Elastic.InitialRetryDelay := 5000; 
  
  LThread := TSendThread.Create('http://localhost:8200', 'secret');
  try
    LData.Json := '{"metadata":{}}';
    LData.Header := 'trace-1';
    LThread.InternalList.Add(LData);
    
    LThread.Start;
    Sleep(200); // Give it time to start and hit the first 429
    
    LStopwatch := TStopwatch.StartNew;
    LThread.Terminate;
    LThread.WaitFor;
    LStopwatch.Stop;
    
    // Should finish much faster than 5 seconds
    Assert.IsTrue(LStopwatch.ElapsedMilliseconds < 1000, 'Terminate took too long: ' + LStopwatch.ElapsedMilliseconds.ToString);
  finally
    LThread.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSendThreadTest);

end.
