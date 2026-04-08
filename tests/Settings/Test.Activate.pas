unit Test.Activate;

interface

uses
  DUnitX.TestFramework,
  Apm4D.Settings;

type
  [TestFixture]
  TTestActivate = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure Should_Activate_And_Deactivate_Correctly;
    
    [Test]
    procedure Should_Handle_Idempotent_Activations;
    
    [Test]
    procedure Should_Handle_Activation_Without_Explicit_Configuration;
  end;

implementation

uses
  System.SysUtils;

{ TTestActivate }

procedure TTestActivate.Setup;
begin
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestActivate.TearDown;
begin
  TApm4DSettings.Deactivate;
  TApm4DSettings.ReleaseInstance;
end;

procedure TTestActivate.Should_Activate_And_Deactivate_Correctly;
begin
  Assert.IsFalse(TApm4DSettings.IsActive, 'Should start deactivated');
  
  TApm4DSettings.Activate;
  Assert.IsTrue(TApm4DSettings.IsActive, 'Should be active after calling Activate');
  
  TApm4DSettings.Deactivate;
  Assert.IsFalse(TApm4DSettings.IsActive, 'Should be deactivated after calling Deactivate');
end;

procedure TTestActivate.Should_Handle_Idempotent_Activations;
begin
  Assert.IsFalse(TApm4DSettings.IsActive, 'Should start deactivated');
  
  // Double activation
  TApm4DSettings.Activate;
  TApm4DSettings.Activate;
  
  Assert.IsTrue(TApm4DSettings.IsActive, 'Should remain active after multiple calls');
  
  // Double deactivation
  TApm4DSettings.Deactivate;
  TApm4DSettings.Deactivate;
  
  Assert.IsFalse(TApm4DSettings.IsActive, 'Should remain deactivated after multiple calls');
end;

procedure TTestActivate.Should_Handle_Activation_Without_Explicit_Configuration;
begin
  // Assuming a clean state with ReleaseInstance in Setup
  // If we activate without configuring anything, it shouldn't raise exceptions
  // and should use defaults.
  Assert.WillNotRaise(
    procedure
    begin
      TApm4DSettings.Activate;
    end,
    Exception,
    'Activating without explicit configuration should not raise exceptions'
  );
  
  Assert.IsTrue(TApm4DSettings.IsActive, 'Should be active');
  Assert.IsNotEmpty(TApm4DSettings.Application.Name, 'Application name should have default value');
  Assert.AreEqual('http://127.0.0.1:8200/intake/v2/events', TApm4DSettings.Elastic.Url, 'Elastic URL should have default value');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestActivate);

end.
