program ElasticAPM4D.Tests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Test.Settings in 'Settings\Test.Settings.pas',
  Test.Context in 'Settings\Test.Context.pas',
  Test.Context.Db in 'Settings\Test.Context.Db.pas',
  Test.Activate in 'Settings\Test.Activate.pas',
  Test.Transaction in 'Transaction\Test.Transaction.pas',
  Test.Span in 'Span\Test.Span.pas',
  Test.Error in 'Core\Test.Error.pas',
  Test.FacadeIntegration in 'Core\Test.FacadeIntegration.pas',
  Test.JSONOutput in 'Serialization\Test.JSONOutput.pas',
  Test.InternalQueue in 'Buffer\Test.InternalQueue.pas',
  Test.ThreadSafety in 'Concurrency\Test.ThreadSafety.pas',
  Test.EdgeCases in 'EdgeCases\Test.EdgeCases.pas',
  Apm4D.Tests.Stacktrace in 'Core\Apm4D.Tests.Stacktrace.pas',
  Test.StacktraceProviders in 'Core\Test.StacktraceProviders.pas',
  Apm4D.SendThread.Test in 'Core\Apm4D.SendThread.Test.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
