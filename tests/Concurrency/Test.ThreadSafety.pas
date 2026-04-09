unit Test.ThreadSafety;

interface

uses
  DUnitX.TestFramework,
  Apm4D,
  Apm4D.Settings;

type
  [TestFixture]
  TTestThreadSafety = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Should_Isolate_Transactions_Per_Thread;

    [Test]
    procedure Should_Read_Settings_Concurrently_Without_Errors;
  end;

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  System.Classes,
  System.Generics.Collections;

procedure TTestThreadSafety.Setup;
begin
  TApm4DSettings.ReleaseInstance;
  TApm4DSettings.Activate;
end;

procedure TTestThreadSafety.TearDown;
begin
  TApm4DSettings.Deactivate;
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestThreadSafety.Should_Isolate_Transactions_Per_Thread;
const
  THREAD_COUNT = 5;
var
  LThreads: array of TThread;
  LCollectedIds: TList<string>;
  LErrors: TList<string>;
  LLock: TCriticalSection;
  LIndex: Integer;
  LUniqueIds: TDictionary<string, Boolean>;
  LItem: string;
begin
  LCollectedIds := TList<string>.Create;
  LErrors := TList<string>.Create;
  LLock := TCriticalSection.Create;
  try
    SetLength(LThreads, THREAD_COUNT);

    for LIndex := 0 to THREAD_COUNT - 1 do
    begin
      LThreads[LIndex] := TThread.CreateAnonymousThread(
        procedure
        var
          LThreadPair: string;
        begin
          try
            TApm4D.StartTransaction('thread_tx_' + TThread.Current.ThreadID.ToString, 'thread-test');
            TApm4D.StartSpan('thread_span', 'method');
            Sleep(5);
            TApm4D.EndSpan;

            LThreadPair := TApm4D.Transaction.Id + '|' + TApm4D.Transaction.Trace_id;

            LLock.Enter;
            try
              LCollectedIds.Add(LThreadPair);
            finally
              LLock.Leave;
            end;

            TApm4D.EndTransaction;
          except
            on E: Exception do
            begin
              LLock.Enter;
              try
                LErrors.Add(E.ClassName + ': ' + E.Message);
              finally
                LLock.Leave;
              end;
            end;
          end;
        end
      );
      LThreads[LIndex].FreeOnTerminate := False;
      LThreads[LIndex].Start;
    end;

    for LIndex := 0 to THREAD_COUNT - 1 do
    begin
      LThreads[LIndex].WaitFor;
      LThreads[LIndex].Free;
    end;

    Assert.AreEqual(0, LErrors.Count, 'No thread should raise runtime errors');
    Assert.AreEqual(THREAD_COUNT, LCollectedIds.Count, 'Each thread should produce one transaction id/trace pair');

    LUniqueIds := TDictionary<string, Boolean>.Create;
    try
      for LItem in LCollectedIds do
      begin
        Assert.IsFalse(LUniqueIds.ContainsKey(LItem), 'Each transaction id/trace pair should be unique per thread');
        LUniqueIds.Add(LItem, True);
      end;
      Assert.AreEqual(THREAD_COUNT, LUniqueIds.Count, 'All collected transaction pairs should be unique');
    finally
      LUniqueIds.Free;
    end;
  finally
    LLock.Free;
    LErrors.Free;
    LCollectedIds.Free;
  end;
end;

procedure TTestThreadSafety.Should_Read_Settings_Concurrently_Without_Errors;
const
  THREAD_COUNT = 8;
var
  LThreads: array of TThread;
  LErrors: TList<string>;
  LLock: TCriticalSection;
  LIndex: Integer;
begin
  TApm4DSettings.Application.Name := 'ParallelReadApp';
  TApm4DSettings.Elastic.Url := 'http://127.0.0.1:8200';

  LErrors := TList<string>.Create;
  LLock := TCriticalSection.Create;
  try
    SetLength(LThreads, THREAD_COUNT);

    for LIndex := 0 to THREAD_COUNT - 1 do
    begin
      LThreads[LIndex] := TThread.CreateAnonymousThread(
        procedure
        begin
          try
            if TApm4DSettings.Application.Name.IsEmpty or TApm4DSettings.Elastic.Url.IsEmpty then
              raise Exception.Create('Concurrent read returned empty settings');
          except
            on E: Exception do
            begin
              LLock.Enter;
              try
                LErrors.Add(E.ClassName + ': ' + E.Message);
              finally
                LLock.Leave;
              end;
            end;
          end;
        end
      );
      LThreads[LIndex].FreeOnTerminate := False;
      LThreads[LIndex].Start;
    end;

    for LIndex := 0 to THREAD_COUNT - 1 do
    begin
      LThreads[LIndex].WaitFor;
      LThreads[LIndex].Free;
    end;

    Assert.AreEqual(0, LErrors.Count, 'Concurrent settings read should not raise errors');
  finally
    LLock.Free;
    LErrors.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThreadSafety);

end.
