unit Test.EdgeCases;

interface

uses
  DUnitX.TestFramework,
  Apm4D,
  Apm4D.Settings;

type
  [TestFixture]
  TTestEdgeCases = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Should_Handle_Empty_Transaction_Name;

    [Test]
    procedure Should_Raise_When_Requesting_Transaction_Without_Start;

    [Test]
    procedure Should_Not_Raise_When_Ending_Without_Transaction;

    [Test]
    procedure Should_Handle_Special_Characters_In_Transaction_Name;

    [Test]
    procedure Should_Raise_When_Starting_Span_Without_Transaction;

    [Test]
    procedure Should_Return_Header_Only_When_Transaction_Exists;
  end;

implementation

uses
  System.SysUtils,
  Apm4D.Share.Types;

procedure TTestEdgeCases.Setup;
begin
  TApm4DSettings.ReleaseInstance;
  TApm4DSettings.Activate;
end;

procedure TTestEdgeCases.TearDown;
begin
  if TApm4D.ExistsTransaction then
    TApm4D.EndTransaction;

  TApm4DSettings.Deactivate;
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestEdgeCases.Should_Handle_Empty_Transaction_Name;
begin
  Assert.WillNotRaise(
    procedure
    begin
      TApm4D.StartTransaction('', 'manual-test');
      TApm4D.EndTransaction;
    end,
    Exception,
    'Starting and ending a transaction with empty name should not crash'
  );
end;

procedure TTestEdgeCases.Should_Raise_When_Requesting_Transaction_Without_Start;
begin
  Assert.WillRaise(
    procedure
    begin
      TApm4D.Transaction;
    end,
    ETransactionNotFound,
    'Requesting current transaction without start should raise the framework transaction-not-found exception'
  );
end;

procedure TTestEdgeCases.Should_Not_Raise_When_Ending_Without_Transaction;
begin
  Assert.WillNotRaise(
    procedure
    begin
      TApm4D.EndSpan;
      TApm4D.EndTransaction;
    end,
    Exception,
    'Ending span/transaction without active transaction should be safe no-op'
  );
end;

procedure TTestEdgeCases.Should_Handle_Special_Characters_In_Transaction_Name;
const
  SPECIAL_NAME = 'Name_with_symbols_123_[]_{}';
begin
  TApm4D.StartTransaction(SPECIAL_NAME, 'special-case');
  try
    Assert.AreEqual(SPECIAL_NAME, TApm4D.Transaction.Name, 'Special characters should be preserved in transaction name');
  finally
    TApm4D.EndTransaction;
  end;
end;

procedure TTestEdgeCases.Should_Raise_When_Starting_Span_Without_Transaction;
begin
  Assert.WillRaise(
    procedure
    begin
      TApm4D.StartSpan('span-without-tx', 'method');
    end,
    EAccessViolation,
    'Starting a span without an open transaction currently raises an access violation and must not silently succeed'
  );
end;

procedure TTestEdgeCases.Should_Return_Header_Only_When_Transaction_Exists;
var
  LHeader: string;
begin
  Assert.AreEqual('', TApm4D.HeaderValue, 'Header should be empty without active transaction');

  TApm4D.StartTransaction('Header Transaction', 'http');
  try
    LHeader := TApm4D.HeaderValue;
    Assert.IsNotEmpty(LHeader, 'Header should be generated when a transaction exists');
    Assert.AreEqual('elastic-apm-traceparent', TApm4D.HeaderKey, 'Header key constant should match the Elastic APM traceparent header name');
  finally
    TApm4D.EndTransaction;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEdgeCases);

end.
