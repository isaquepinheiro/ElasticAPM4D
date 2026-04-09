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
    procedure TestPushToQueue;
    [Test]
    procedure TestQueueLimit;
  end;

implementation

{ TTestQueue }

procedure TTestQueue.Setup;
begin
  // Inicializa o ambiente para a fila singleton funcionar
  TApm4DSettings.Application.Name := 'TestApp';
  TApm4DSettings.Elastic.Url := 'http://127.0.0.1:8200/intake/v2/events';
  TApm4DSettings.Activate;
end;

procedure TTestQueue.TearDown;
begin
  TApm4DSettings.Deactivate;
end;

procedure TTestQueue.TestPushToQueue;
begin
  // Empilha um item básico
  TQueueSingleton.StackUp('{"test": 1}', 'traceparent=123');
  Assert.Pass('Push to queue should not raise exceptions');
end;

procedure TTestQueue.TestQueueLimit;
var
  I: Integer;
begin
  // Empilha além do limite (MaxJsonPerThread, que é 50 por padrão ou similar)
  for I := 1 to (TApm4DSettings.Elastic.MaxJsonPerThread + 10) do
  begin
    TQueueSingleton.StackUp('{"test": ' + IntToStr(I) + '}', 'traceparent=123');
  end;
  Assert.Pass('Push beyond limit should be handled safely');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQueue);

end.
