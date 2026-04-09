unit Test.JSONOutput;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON, Apm4D.Serializer, Apm4D.Transaction, Apm4D.Span, Apm4D.Error;

type
  [TestFixture]
  TTestSerializer = class
  public
    [Test]
    procedure TestSerializeTransaction;
    [Test]
    procedure TestSerializeSpan;
    [Test]
    procedure TestSerializeError;
    [Test]
    procedure TestSerializeEmptyObject;
  end;

implementation

{ TTestSerializer }

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

initialization
  TDUnitX.RegisterTestFixture(TTestSerializer);

end.
