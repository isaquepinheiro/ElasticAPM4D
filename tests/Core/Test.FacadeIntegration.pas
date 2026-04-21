unit Test.FacadeIntegration;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Apm4D,
  Apm4D.Settings,
  Apm4D.Share.Types,
  Apm4D.Span;

type
  [TestFixture]
  TTestFacadeIntegration = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Should_Set_Failure_Outcome_After_AddError;

    [Test]
    procedure Should_Populate_Error_Type_And_Message_From_Exception;

    [Test]
    procedure Should_Increment_SpanCount_When_Starting_Spans;

    [Test]
    procedure Should_Propagate_TraceId_From_Transaction_To_Span;

    // [Test]
    // procedure Should_Support_Full_Transaction_Span_Error_Flow_Without_Raising;
  end;

implementation

{ TTestFacadeIntegration }

procedure TTestFacadeIntegration.Setup;
begin
  TApm4DSettings.ReleaseInstance;
  TApm4DSettings.Activate;
end;

procedure TTestFacadeIntegration.TearDown;
begin
  if TApm4D.ExistsTransaction then
    TApm4D.EndTransaction;
  TApm4DSettings.Deactivate;
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestFacadeIntegration.Should_Set_Failure_Outcome_After_AddError;
var
  LException: Exception;
begin
  TApm4D.StartTransaction('Tx_Failure', 'test');
  LException := Exception.Create('simulated error');
  try
    TApm4D.AddError(LException);
  finally
    LException.Free;
  end;

  Assert.AreEqual('failure', TApm4D.Transaction.Outcome,
    'Transaction outcome must be failure after AddError');
  Assert.AreEqual('simulated error', TApm4D.Transaction.Result,
    'Transaction result must be set to the exception message after AddError');

  TApm4D.EndTransaction;
end;

procedure TTestFacadeIntegration.Should_Populate_Error_Type_And_Message_From_Exception;
begin
  TApm4D.StartTransaction('Tx_Error_Props', 'test');
  try
    raise EArgumentException.Create('invalid param');
  except
    on LE: Exception do
    begin
      TApm4D.AddError(LE);
      Assert.AreEqual('invalid param', TApm4D.Transaction.Result,
        'Transaction result must equal exception message after AddError');
      Assert.AreEqual('failure', TApm4D.Transaction.Outcome,
        'Transaction outcome must be failure after exception is added');
    end;
  end;
  TApm4D.EndTransaction;
end;

procedure TTestFacadeIntegration.Should_Increment_SpanCount_When_Starting_Spans;
begin
  TApm4D.StartTransaction('Tx_SpanCount', 'test');

  Assert.AreEqual(0, TApm4D.Transaction.Span_count.Started,
    'Span count must be 0 before any span is started');

  TApm4D.StartSpan('Span1', 'method');
  Assert.AreEqual(1, TApm4D.Transaction.Span_count.Started,
    'Span count must be 1 after starting one span');

  TApm4D.StartSpan('Span2', 'method');
  Assert.AreEqual(2, TApm4D.Transaction.Span_count.Started,
    'Span count must be 2 after starting two spans');

  TApm4D.EndSpan;
  TApm4D.EndSpan;
  TApm4D.EndTransaction;
end;

procedure TTestFacadeIntegration.Should_Propagate_TraceId_From_Transaction_To_Span;
var
  LTraceId: string;
  LTransactionId: string;
  LSpan: TSpan;
begin
  TApm4D.StartTransaction('Tx_TraceId', 'test');
  LTraceId := TApm4D.Transaction.Trace_id;
  LTransactionId := TApm4D.Transaction.Id;

  LSpan := TApm4D.StartSpan('Span_TraceId', 'method');

  Assert.AreEqual(LTraceId, LSpan.Trace_id,
    'Span trace_id must match the parent transaction trace_id');
  Assert.AreEqual(LTransactionId, LSpan.Transaction_id,
    'Span transaction_id must be the transaction id');

  TApm4D.EndSpan;
  TApm4D.EndTransaction;
end;

{
procedure TTestFacadeIntegration.Should_Support_Full_Transaction_Span_Error_Flow_Without_Raising;
begin
  Assert.WillNotRaise(
    procedure
    begin
      TApm4D.StartTransaction('Full_Flow', 'test');

      TApm4D.StartSpan('Span_DB', 'db');
      TApm4D.SetSQLToCurrentSpan('SELECT 1 FROM DUAL');
      TApm4D.EndSpan;

      TApm4D.StartSpan('Span_HTTP', 'external');
      TApm4D.EndSpan(200);

      try
        raise Exception.Create('test error in full flow');
      except
        on LE: Exception do
          TApm4D.AddError(LE);
      end;

      TApm4D.EndTransaction;
    end,
    'Complete facade flow (transaction + spans + error) must not raise'
  );
end;
}

initialization
  TDUnitX.RegisterTestFixture(TTestFacadeIntegration);

end.
