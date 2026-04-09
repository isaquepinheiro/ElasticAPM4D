unit Test.InternalQueue;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes,
  Apm4D.QueueSingleton, Apm4D.Settings;

type
  [TestFixture]
  TTestQueue = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Should_Not_Raise_When_Pushing_Single_Item;

    [Test]
    procedure Should_Silently_Discard_When_Inactive;

    [Test]
    procedure Should_Not_Raise_When_Pushing_Beyond_Limit;
  end;

implementation

{ TTestQueue }

procedure TTestQueue.Setup;
begin
  TApm4DSettings.ReleaseInstance;
  TApm4DSettings.Application.Name := 'TestApp';
  TApm4DSettings.Elastic.Url := 'http://127.0.0.1:8200';
  TApm4DSettings.Activate;
end;

procedure TTestQueue.TearDown;
begin
  TApm4DSettings.Deactivate;
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestQueue.Should_Not_Raise_When_Pushing_Single_Item;
begin
  Assert.WillNotRaise(
    procedure
    begin
      TQueueSingleton.StackUp('{"test": 1}', 'traceparent=123');
    end,
    Exception,
    'Pushing a single item to an active queue must not raise'
  );
end;

procedure TTestQueue.Should_Silently_Discard_When_Inactive;
begin
  TApm4DSettings.Deactivate;
  Assert.WillNotRaise(
    procedure
    begin
      TQueueSingleton.StackUp('{"should_be_ignored": true}', 'traceparent=000');
    end,
    Exception,
    'StackUp while inactive must silently discard the item without raising'
  );
end;

procedure TTestQueue.Should_Not_Raise_When_Pushing_Beyond_Limit;
var
  LIndex: Integer;
  LLimit: Integer;
begin
  LLimit := TApm4DSettings.Elastic.MaxJsonPerThread;
  Assert.WillNotRaise(
    procedure
    begin
      for LIndex := 1 to LLimit + 10 do
        TQueueSingleton.StackUp('{"seq": ' + IntToStr(LIndex) + '}', 'traceparent=seq');
    end,
    Exception,
    'Pushing beyond MaxJsonPerThread must not raise an exception'
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQueue);

end.
