unit Test.DataInterceptors;

interface

uses
  DUnitX.TestFramework, Data.DB, System.Classes, Apm4D;

type
  [TestFixture]
  TTestDataInterceptors = class
  private
    FDataModule: TDataModule;
    FDataSet: TDataSet;
    FBeforeCalled: Boolean;
    FSpanActiveDuringEvent: Boolean;
    procedure MockBeforeEvent(ADataSet: TDataSet);
  public
    [Setup]
    procedure Setup;
    [Teardown]
    procedure Teardown;
    [Test]
    procedure TestDataSetOpenStartsSpan;
    [Test]
    procedure TestDataSetDeleteStartsSpan;
  end;

implementation

uses
  Apm4D.Settings, Apm4D.Interceptor.Handler, System.SysUtils;

type
  TTestDataSet = class(TDataSet)
  protected
    function IsCursorOpen: Boolean; override;
  public
    procedure Open;
    procedure Delete;
  end;

{ TTestDataSet }

procedure TTestDataSet.Delete;
begin
  if Assigned(BeforeDelete) then BeforeDelete(Self);
  if Assigned(AfterDelete) then AfterDelete(Self);
end;

function TTestDataSet.IsCursorOpen: Boolean;
begin
  Result := True;
end;

procedure TTestDataSet.Open;
begin
  if Assigned(BeforeOpen) then BeforeOpen(Self);
  if Assigned(AfterOpen) then AfterOpen(Self);
end;

{ TTestDataInterceptors }

procedure TTestDataInterceptors.Setup;
begin
  TApm4DSettings.Activate;
  FDataModule := TDataModule.Create(nil);
  FDataModule.Name := 'TestDataModule';
  FDataSet := TTestDataSet.Create(FDataModule);
  FDataSet.Name := 'TestDataSet';
end;

procedure TTestDataInterceptors.Teardown;
begin
  FDataModule.Free;
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestDataInterceptors.MockBeforeEvent(ADataSet: TDataSet);
begin
  FBeforeCalled := True;
  FSpanActiveDuringEvent := (TApm4D.Span <> nil);
end;

procedure TTestDataInterceptors.TestDataSetOpenStartsSpan;
begin
  FBeforeCalled := False;
  TApm4D.StartTransaction('TestTrans');
  try
    FDataSet.BeforeOpen := MockBeforeEvent;

    TApm4DInterceptorBuilder.CreateDefault(FDataModule);

    TTestDataSet(FDataSet).Open;
    Assert.IsTrue(FBeforeCalled, 'Original BeforeOpen should have been called');
    Assert.IsTrue(FSpanActiveDuringEvent, 'Span should be active during BeforeOpen');
  finally
    TApm4D.EndTransaction;
  end;
end;

procedure TTestDataInterceptors.TestDataSetDeleteStartsSpan;
begin
  FBeforeCalled := False;
  TApm4D.StartTransaction('TestTrans');
  try
    FDataSet.BeforeDelete := MockBeforeEvent;

    TApm4DInterceptorBuilder.CreateDefault(FDataModule);

    TTestDataSet(FDataSet).Delete;
    Assert.IsTrue(FBeforeCalled, 'Original BeforeDelete should have been called');
    Assert.IsTrue(FSpanActiveDuringEvent, 'Span should be active during BeforeDelete');
  finally
    TApm4D.EndTransaction;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDataInterceptors);

end.
