unit Test.VclInterceptors;

interface

uses
  DUnitX.TestFramework, Vcl.StdCtrls, Vcl.Buttons, Vcl.Forms, System.Classes, Apm4D;

type
  [TestFixture]
  TTestVclInterceptors = class
  private
    FForm: TForm;
    FButton: TButton;
    FBitBtn: TBitBtn;
    FClicked: Boolean;
    FActiveTransactionDuringClick: Boolean;
    procedure MockOnClick(ASender: TObject);
    procedure MockOnClickCheckSpan(ASender: TObject);
  public
    [Setup]
    procedure Setup;
    [Teardown]
    procedure Teardown;
    [Test]
    procedure TestButtonClickStartsTransaction;
    [Test]
    procedure TestBitBtnClickStartsTransaction;
    [Test]
    procedure TestClickWithActiveTransactionStartsSpan;
  end;

implementation

uses
  Apm4D.Settings, Apm4D.Interceptor.Handler, System.SysUtils;

procedure TTestVclInterceptors.Setup;
begin
  TApm4DSettings.Activate;
  FForm := TForm.Create(nil);
  FForm.Name := 'TestForm';
  
  FButton := TButton.Create(FForm);
  FButton.Name := 'TestButton';
  FButton.Parent := FForm;

  FBitBtn := TBitBtn.Create(FForm);
  FBitBtn.Name := 'TestBitBtn';
  FBitBtn.Parent := FForm;
end;

procedure TTestVclInterceptors.Teardown;
begin
  FForm.Free;
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestVclInterceptors.MockOnClick(ASender: TObject);
begin
  FClicked := True;
  FActiveTransactionDuringClick := TApm4D.ExistsTransaction;
end;

procedure TTestVclInterceptors.MockOnClickCheckSpan(ASender: TObject);
begin
  FClicked := True;
  FActiveTransactionDuringClick := TApm4D.ExistsTransaction and (TApm4D.Span <> nil);
end;

procedure TTestVclInterceptors.TestButtonClickStartsTransaction;
begin
  FClicked := False;
  FButton.OnClick := MockOnClick;

  TApm4DInterceptorBuilder.CreateDefault(FForm);

  FButton.Click;
  Assert.IsTrue(FClicked, 'Original OnClick should have been called');
  Assert.IsTrue(FActiveTransactionDuringClick, 'Transaction should be active during click');
  Assert.IsFalse(TApm4D.ExistsTransaction, 'Transaction should have ended after click');
end;

procedure TTestVclInterceptors.TestBitBtnClickStartsTransaction;
begin
  FClicked := False;
  FBitBtn.OnClick := MockOnClick;

  TApm4DInterceptorBuilder.CreateDefault(FForm);

  FBitBtn.Click;
  Assert.IsTrue(FClicked, 'Original OnClick should have been called');
  Assert.IsTrue(FActiveTransactionDuringClick, 'Transaction should be active during click');
  Assert.IsFalse(TApm4D.ExistsTransaction, 'Transaction should have ended after click');
end;

procedure TTestVclInterceptors.TestClickWithActiveTransactionStartsSpan;
begin
  TApm4D.StartTransaction('MainTrans');
  try
    FClicked := False;
    FButton.OnClick := MockOnClickCheckSpan;

    TApm4DInterceptorBuilder.CreateDefault(FForm);

    FButton.Click;
    Assert.IsTrue(FClicked, 'Original OnClick should have been called');
    Assert.IsTrue(FActiveTransactionDuringClick, 'Span should be active during click when transaction already exists');
  finally
    TApm4D.EndTransaction;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVclInterceptors);

end.
