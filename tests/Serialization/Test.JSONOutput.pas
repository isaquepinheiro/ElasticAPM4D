unit Test.JSONOutput;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON, Apm4D.Serializer, Apm4D.Transaction, Apm4D.Span, Apm4D.Error,
  Apm4D.Settings;

type
  [TestFixture]
  TTestSerializer = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSerializeTransaction;
    [Test]
    procedure TestSerializeSpan;
    [Test]
    procedure TestSerializeError;
    [Test]
    procedure TestSerializeEmptyObject;

  [Test]
  procedure TestTransactionContainsRequiredElasticFields;

  [Test]
  procedure TestSpanContainsRequiredElasticFields;

  [Test]
  procedure TestErrorContainsRequiredElasticFields;
implementation

{ TTestSerializer }

procedure TTestSerializer.Setup;
begin
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestSerializer.TearDown;
begin
  TApm4DSettings.Deactivate;
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestSerializer.TestSerializeTransaction;
var
  LTransaction: TTransaction;
  LJsonString: string;
  LJsonValue: TJSONValue;
begin
  LTransaction := TTransaction.Create;
  try
    LTransaction.Start('TestTransaction', 'request');
    LTransaction.ToEnd; // success by default

    LJsonString := LTransaction.ToJsonString; // Internamente chama TApm4DSerializer.ToJSON

    Assert.IsTrue(LJsonString.StartsWith('{"transaction":'), 'Should wrap with property name');
    Assert.IsTrue(LJsonString.Contains('"name":"TestTransaction"'), 'Should contain name');
    Assert.IsTrue(LJsonString.Contains('"type":"request"'), 'Should contain type');
    
    // Validar se é um JSON parseável
    LJsonValue := TJSONObject.ParseJSONValue(LJsonString);
    try
      Assert.IsNotNull(LJsonValue, 'Should be valid JSON');
      Assert.IsTrue(LJsonValue is TJSONObject, 'Should be a JSON object');
    finally
      LJsonValue.Free;
    end;
  finally
    LTransaction.Free;
  end;
end;

procedure TTestSerializer.TestSerializeSpan;
var
  LSpan: TSpan;
  LJsonString: string;
  LJsonValue: TJSONValue;
begin
  LSpan := TSpan.Create('trace123', 'trans123', 'parent123');
  try
    LSpan.Start('TestSpan', 'db');
    LSpan.ToEnd;

    LJsonString := LSpan.ToJsonString;

    Assert.IsTrue(LJsonString.StartsWith('{"span":'), 'Should wrap with property name');
    Assert.IsTrue(LJsonString.Contains('"name":"TestSpan"'), 'Should contain name');
    Assert.IsTrue(LJsonString.Contains('"type":"db"'), 'Should contain type');
    Assert.IsTrue(LJsonString.Contains('"action":"query"'), 'Should contain default action for db');
    
    LJsonValue := TJSONObject.ParseJSONValue(LJsonString);
    try
      Assert.IsNotNull(LJsonValue, 'Should be valid JSON');
      Assert.IsTrue(LJsonValue is TJSONObject, 'Should be a JSON object');
    finally
      LJsonValue.Free;
    end;
  finally
    LSpan.Free;
  end;
end;

procedure TTestSerializer.TestSerializeError;
var
  LError: TError;
  LJsonString: string;
  LJsonValue: TJSONValue;
begin
  LError := TError.Create('trace123', 'trans123', 'parent123');
  try
    LError.Exception.&Message := 'Test Exception';
    LError.Exception.&Type := 'Exception';

    LJsonString := LError.ToJsonString;

    Assert.IsTrue(LJsonString.StartsWith('{"error":'), 'Should wrap with property name');
    Assert.IsTrue(LJsonString.Contains('"message":"Test Exception"'), 'Should contain message');
    
    LJsonValue := TJSONObject.ParseJSONValue(LJsonString);
    try
      Assert.IsNotNull(LJsonValue, 'Should be valid JSON');
      Assert.IsTrue(LJsonValue is TJSONObject, 'Should be a JSON object');
    finally
      LJsonValue.Free;
    end;
  finally
    LError.Free;
  end;
end;

procedure TTestSerializer.TestSerializeEmptyObject;
var
  LObj: TObject;
  LJsonString: string;
begin
  LObj := TObject.Create;
  try
    LJsonString := TApm4DSerializer.ToJSON(LObj, 'empty');
    Assert.AreEqual('{"empty": {}}', LJsonString);
  finally
    LObj.Free;
  end;
end;

procedure TTestSerializer.TestTransactionContainsRequiredElasticFields;
var
  LTransaction: TTransaction;
  LJsonString: string;
  LRoot: TJSONObject;
  LTx: TJSONObject;
begin
  LTransaction := TTransaction.Create;
  try
    LTransaction.Start('RequiredFieldsTx', 'test');
    LTransaction.ToEnd;
    LJsonString := LTransaction.ToJsonString;

    LRoot := TJSONObject.ParseJSONValue(LJsonString) as TJSONObject;
    try
      LTx := LRoot.GetValue<TJSONObject>('transaction');
      Assert.IsNotNull(LTx, 'Root must have a "transaction" key');
      Assert.IsNotEmpty(LTx.GetValue<string>('id'),
        'Transaction JSON must contain non-empty "id"');
      Assert.IsNotEmpty(LTx.GetValue<string>('trace_id'),
        'Transaction JSON must contain non-empty "trace_id"');
      Assert.IsTrue(LTx.GetValue<Int64>('timestamp') > 0,
        'Transaction JSON must contain a positive "timestamp"');
      Assert.IsTrue(LTx.GetValue<Int64>('duration') >= 0,
        'Transaction JSON must contain a non-negative "duration"');
      Assert.IsNotEmpty(LTx.GetValue<string>('name'),
        'Transaction JSON must contain non-empty "name"');
      Assert.IsNotEmpty(LTx.GetValue<string>('type'),
        'Transaction JSON must contain non-empty "type"');
    finally
      LRoot.Free;
    end;
  finally
    LTransaction.Free;
  end;
end;

procedure TTestSerializer.TestSpanContainsRequiredElasticFields;
var
  LSpan: TSpan;
  LJsonString: string;
  LRoot: TJSONObject;
  LSpanObj: TJSONObject;
begin
  LSpan := TSpan.Create('trace_aaa', 'trans_bbb', 'parent_ccc');
  try
    LSpan.Start('RequiredFieldsSpan', 'db');
    LSpan.ToEnd;
    LJsonString := LSpan.ToJsonString;

    LRoot := TJSONObject.ParseJSONValue(LJsonString) as TJSONObject;
    try
      LSpanObj := LRoot.GetValue<TJSONObject>('span');
      Assert.IsNotNull(LSpanObj, 'Root must have a "span" key');
      Assert.IsNotEmpty(LSpanObj.GetValue<string>('id'),
        'Span JSON must contain non-empty "id"');
      Assert.IsNotEmpty(LSpanObj.GetValue<string>('trace_id'),
        'Span JSON must contain non-empty "trace_id"');
      Assert.IsNotEmpty(LSpanObj.GetValue<string>('transaction_id'),
        'Span JSON must contain non-empty "transaction_id"');
      Assert.IsNotEmpty(LSpanObj.GetValue<string>('parent_id'),
        'Span JSON must contain non-empty "parent_id"');
      Assert.IsTrue(LSpanObj.GetValue<Int64>('timestamp') > 0,
        'Span JSON must contain a positive "timestamp"');
      Assert.IsTrue(LSpanObj.GetValue<Int64>('duration') >= 0,
        'Span JSON must contain a non-negative "duration"');
    finally
      LRoot.Free;
    end;
  finally
    LSpan.Free;
  end;
end;

procedure TTestSerializer.TestErrorContainsRequiredElasticFields;
var
  LError: TError;
  LJsonString: string;
  LRoot: TJSONObject;
  LErrorObj: TJSONObject;
  LExceptionObj: TJSONObject;
begin
  LError := TError.Create('trace_x', 'trans_y', 'parent_z');
  try
    LError.Exception.&Message := 'Required field test';
    LError.Exception.&Type := 'ETest';
    LJsonString := LError.ToJsonString;

    LRoot := TJSONObject.ParseJSONValue(LJsonString) as TJSONObject;
    try
      LErrorObj := LRoot.GetValue<TJSONObject>('error');
      Assert.IsNotNull(LErrorObj, 'Root must have an "error" key');
      Assert.IsNotEmpty(LErrorObj.GetValue<string>('id'),
        'Error JSON must contain non-empty "id"');
      Assert.IsNotEmpty(LErrorObj.GetValue<string>('trace_id'),
        'Error JSON must contain non-empty "trace_id"');
      Assert.IsNotEmpty(LErrorObj.GetValue<string>('transaction_id'),
        'Error JSON must contain non-empty "transaction_id"');
      Assert.IsTrue(LErrorObj.GetValue<Int64>('timestamp') > 0,
        'Error JSON must contain a positive "timestamp"');
      LExceptionObj := LErrorObj.GetValue<TJSONObject>('exception');
      Assert.IsNotNull(LExceptionObj,
        'Error JSON must contain an "exception" object');
      Assert.IsNotEmpty(LExceptionObj.GetValue<string>('message'),
        'Exception object must contain non-empty "message"');
    finally
      LRoot.Free;
    end;
  finally
    LError.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSerializer);

end.
