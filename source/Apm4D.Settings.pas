{ ******************************************************* }
{ }
{ Delphi Elastic Apm Agent }
{ }
{ Developed by Juliano Eichelberger }
{ }
{ ******************************************************* }
unit Apm4D.Settings;

interface

uses
  System.SyncObjs,
  System.Generics.Collections,
{$IFDEF MSWINDOWS}
  Apm4D.Interceptor,
  Apm4D.Interceptor.DataSet,
  Apm4D.Interceptor.OnClick,
  Apm4D.Interceptor.RESTRequest,
{$ENDIF}
  Apm4D.Metricset.Base,
  Apm4D.Share.Stacktrace,
  Apm4D.Settings.Database,
  Apm4D.Settings.User,
  Apm4D.Settings.Application,
  Apm4D.Settings.Elastic,
  Apm4D.Settings.Log,
  Apm4D.Share.Types;

type
{$IFDEF MSWINDOWS}
  TApm4DInterceptOnClick = Apm4D.Interceptor.OnClick.TApm4DInterceptOnClick;
  TApm4DInterceptDataSet = Apm4D.Interceptor.DataSet.TApm4DInterceptDataSet;
  TApm4DInterceptRESTRequest = Apm4D.Interceptor.RESTRequest.TApm4DInterceptRESTRequest;
{$ENDIF}
  TApm4DMetricsetClass = Apm4D.Metricset.Base.TApm4DMetricsetClass; 
  
  /// <summary>
  /// It's a singleton class. You can configure global application settings.
  /// </summary>
  TApm4DSettings = class
  private
    class var FLock: TCriticalSection;
    class var FIsActive: Boolean;
    class var FDatabase: TDatabaseSettings;
    class var FUser: TUserSettings;
    class var FApplication: TApplicationSettings;
    class var FElastic: TElasticSettings;
    class var FLog: TLogSettings;
    class var FStackTracer: TStackTracerClass;
    class var FStacktraceProvider: TApm4DStacktraceProvider;
{$IFDEF MSWINDOWS}
    class var FInterceptors: TDictionary<TApm4DInterceptorClass, TArray<TClass>>;
{$ENDIF}
    class var FMetricsets: TList<TApm4DMetricsetClass>;
    class var FHttpClientFactory: TApm4DHttpClientFactory;
    class procedure _RegisterDefaults; static;
  public
    class function Database: TDatabaseSettings; static;
    class function User: TUserSettings; static;
    class function Application: TApplicationSettings; static;
    class function Elastic: TElasticSettings; static;
    class function Log: TLogSettings; static;

    class procedure Activate;
    class procedure Deactivate;
    class function IsActive: boolean;

    class procedure ReleaseInstance;

{$IFDEF MSWINDOWS}
    class procedure RegisterInterceptor(const AInterceptor: TApm4DInterceptorClass; const AClasses: TArray<TClass>);
    class function GetInterceptors: TDictionary<TApm4DInterceptorClass, TArray<TClass>>;
{$ENDIF}
    class procedure AddStackTracer(const AStackTracer: TStackTracerClass);
    class function CreateStackTracer: TStackTracer;

    class function StacktraceProvider: TApm4DStacktraceProvider; static;
    class procedure SetStacktraceProvider(const AValue: TApm4DStacktraceProvider); static;
    /// <summary>
    /// Register a custom metricset class.
    /// </summary>
    class procedure RegisterMetricset(const AMetricsetClass: TApm4DMetricsetClass);
    
    /// <summary>
    /// Get all registered metricsets.
    /// </summary>
    class function GetMetricsets: TList<TApm4DMetricsetClass>;
    
    /// <summary>
    /// Clear all registered metricsets.
    /// </summary>
    class procedure ClearMetricsets;

    class procedure SetHttpClientFactory(const AFactory: TApm4DHttpClientFactory);
    class function CreateHttpClient: IApm4DHttpClient;
  end;

implementation

Uses
{$IFDEF MSWINDOWS} Vcl.Forms, Vcl.StdCtrls, Vcl.Buttons, {$ENDIF}
  System.SysUtils, System.DateUtils, System.Variants, Apm4D.HttpClient.Indy,
  Data.DB, REST.Client
  {$IFDEF jcl}, Apm4D.Share.Stacktrace.Jcl{$ENDIF}
  {$IFDEF madExcept}, Apm4D.Share.Stacktrace.MadExcept{$ENDIF}
  {$IFDEF EUREKALOG}, Apm4D.Share.Stacktrace.EurekaLog{$ENDIF};


{ TApm4DSettings }

class function TApm4DSettings.Database: TDatabaseSettings;
begin
  FLock.Enter;
  try
    if FDatabase = nil then
      FDatabase := TDatabaseSettings.Create;
    Result := FDatabase;
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.User: TUserSettings;
begin
  FLock.Enter;
  try
    if FUser = nil then
      FUser := TUserSettings.Create;
    Result := FUser;
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.Application: TApplicationSettings;
begin
  FLock.Enter;
  try
    if FApplication = nil then
      FApplication := TApplicationSettings.Create;
    Result := FApplication;
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.Elastic: TElasticSettings;
begin
  FLock.Enter;
  try
    if FElastic = nil then
      FElastic := TElasticSettings.Create;
    Result := FElastic;
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.Log: TLogSettings;
begin
  FLock.Enter;
  try
    if FLog = nil then
      FLog := TLogSettings.Create;
    Result := FLog;
  finally
    FLock.Leave;
  end;
end;

class procedure TApm4DSettings.AddStackTracer(const AStackTracer: TStackTracerClass);
begin
  FLock.Enter;
  try
    FStackTracer := AStackTracer;
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.CreateStackTracer: TStackTracer;
var
  LProvider: TApm4DStacktraceProvider;
begin
  FLock.Enter;
  try
    Result := nil;
    LProvider := FStacktraceProvider;

    if LProvider = spAutomatic then
    begin
      {$IFDEF madExcept}
      LProvider := spMadExcept;
      {$ELSEIF DEFINED(EUREKALOG)}
      LProvider := spEurekaLog;
      {$ELSEIF DEFINED(jcl)}
      LProvider := spJcl;
      {$ELSE}
      LProvider := spNone;
      {$ENDIF}
    end;

    case LProvider of
      spMadExcept:
        begin
          {$IFDEF madExcept}
          Result := TStacktraceMadExcept.Create;
          {$ENDIF}
        end;
      spEurekaLog:
        begin
          {$IFDEF EUREKALOG}
          Result := TStacktraceEurekaLog.Create;
          {$ENDIF}
        end;
      spJcl:
        begin
          {$IFDEF jcl}
          Result := TStacktraceJCL.Create;
          {$ENDIF}
        end;
      spNone: Result := nil;
    end;

    if (Result = nil) and Assigned(FStackTracer) then
      Result := FStackTracer.Create;
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.StacktraceProvider: TApm4DStacktraceProvider;
begin
  FLock.Enter;
  try
    Result := FStacktraceProvider;
  finally
    FLock.Leave;
  end;
end;

class procedure TApm4DSettings.SetStacktraceProvider(const AValue: TApm4DStacktraceProvider);
begin
  FLock.Enter;
  try
    FStacktraceProvider := AValue;
  finally
    FLock.Leave;
  end;
end;

class procedure TApm4DSettings.ReleaseInstance;
begin
  FLock.Enter;
  try
    if FLog <> nil then
      FreeAndNil(FLog);
    if FElastic <> nil then
      FreeAndNil(FElastic);
    if FApplication <> nil then
      FreeAndNil(FApplication);
    if FUser <> nil then
      FreeAndNil(FUser);
    if FDatabase <> nil then
      FreeAndNil(FDatabase);
{$IFDEF MSWINDOWS}
    if FInterceptors <> nil then
      FreeAndNil(FInterceptors);
{$ENDIF}
    if Assigned(FMetricsets) then
      FreeAndNil(FMetricsets);
    FStackTracer := nil;
    FStacktraceProvider := spAutomatic;
  finally
    FLock.Leave;
  end;
end;

class procedure TApm4DSettings.Activate;
begin
  FLock.Enter;
  try
    Randomize;
    FIsActive := True;
  finally
    FLock.Leave;
  end;
end;

class procedure TApm4DSettings.Deactivate;
begin
  FLock.Enter;
  try
    FIsActive := False;
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.IsActive: boolean;
begin
  FLock.Enter;
  try
    Result := FIsActive;
  finally
    FLock.Leave;
  end;
end;

{$IFDEF MSWINDOWS}


class procedure TApm4DSettings.RegisterInterceptor(const AInterceptor: TApm4DInterceptorClass; const AClasses: TArray<TClass>);
begin
  FLock.Enter;
  try
    if not assigned(FInterceptors) then
      FInterceptors := TDictionary < TApm4DInterceptorClass, TArray < TClass >>.Create;
    FInterceptors.AddOrSetValue(AInterceptor, AClasses);
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.GetInterceptors: TDictionary<TApm4DInterceptorClass, TArray<TClass>>;
begin
  FLock.Enter;
  try
    if not assigned(FInterceptors) then
    begin
      FInterceptors := TDictionary < TApm4DInterceptorClass, TArray < TClass >>.Create;
      _RegisterDefaults;
    end;

    Result := FInterceptors;
  finally
    FLock.Leave;
  end;
end;

class procedure TApm4DSettings._RegisterDefaults;
begin
{$IFDEF MSWINDOWS}
  RegisterInterceptor(TApm4DInterceptOnClick, [TButton, TBitBtn]);
  RegisterInterceptor(TApm4DInterceptDataSet, [TDataSet]);
  RegisterInterceptor(TApm4DInterceptRESTRequest, [TCustomRESTRequest]);
{$ENDIF}
end;

{$ENDIF}

class procedure TApm4DSettings.RegisterMetricset(const AMetricsetClass: TApm4DMetricsetClass);
begin
  FLock.Enter;
  try
    if not Assigned(FMetricsets) then
      FMetricsets := TList<TApm4DMetricsetClass>.Create;
    
    // Avoid duplicates
    if not FMetricsets.Contains(AMetricsetClass) then
      FMetricsets.Add(AMetricsetClass);
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.GetMetricsets: TList<TApm4DMetricsetClass>;
begin
  FLock.Enter;
  try
    if not Assigned(FMetricsets) then
      FMetricsets := TList<TApm4DMetricsetClass>.Create;
    
    Result := FMetricsets;
  finally
    FLock.Leave;
  end;
end;

class procedure TApm4DSettings.ClearMetricsets;
begin
  FLock.Enter;
  try
    if Assigned(FMetricsets) then
      FMetricsets.Clear;
  finally
    FLock.Leave;
  end;
end;

class procedure TApm4DSettings.SetHttpClientFactory(const AFactory: TApm4DHttpClientFactory);
begin
  FLock.Enter;
  try
    FHttpClientFactory := AFactory;
  finally
    FLock.Leave;
  end;
end;

class function TApm4DSettings.CreateHttpClient: IApm4DHttpClient;
begin
  FLock.Enter;
  try
    Result := nil;
    if Assigned(FHttpClientFactory) then
      Result := FHttpClientFactory();
  finally
    FLock.Leave;
  end;
end;

initialization

TApm4DSettings.FLock := TCriticalSection.Create;
TApm4DSettings.FHttpClientFactory := TApm4DIdHttpClientFactory;
TApm4DSettings.FStacktraceProvider := spAutomatic;

finalization

TApm4DSettings.ReleaseInstance;
TApm4DSettings.FLock.Free;

end.
