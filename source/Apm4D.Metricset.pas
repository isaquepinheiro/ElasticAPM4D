{ ******************************************************* }
{ }
{ Delphi Elastic Apm Agent }
{ }
{ Developed by Juliano Eichelberger }
{ }
{ ******************************************************* }
unit Apm4D.Metricset;

interface

uses
  System.SysUtils, Classes, Generics.Collections,
  System.Threading;

type
  TMetricSets = class
  public
    class procedure CollectAsync(AOnCollect: TProc<string>);
  end;

implementation

uses
  Apm4D.Metricset.Base, Apm4D.Settings;

{ TMetricSet }

class procedure TMetricSets.CollectAsync(AOnCollect: TProc<string>);
var
  MetricsetClasses: TList<TApm4DMetricsetClass>;
  Tasks: array of ITask;
  I: Integer;
begin
  MetricsetClasses := TApm4DSettings.GetMetricsets;
  if not Assigned(MetricsetClasses) or (MetricsetClasses.Count = 0) then
    Exit;

  // Create parallel tasks for each metricset
  SetLength(Tasks, MetricsetClasses.Count);
  
  for I := 0 to MetricsetClasses.Count - 1 do
  begin
    Tasks[I] := TTask.Create(
      procedure
      var
        Metricset: TApm4DMetricsetBase;
        JsonString: string;
        MetricsetClass: TApm4DMetricsetClass;
      begin
        MetricsetClass := MetricsetClasses[I];
        Metricset := MetricsetClass.Create;
        try
          JsonString := Metricset.ToJsonString;
          // Call the callback in a thread-safe manner
          TThread.Queue(nil, 
            procedure
            begin
              AOnCollect(JsonString);
            end
          );
        finally
          Metricset.Free;
        end;
      end
    );
    Tasks[I].Start;
  end;
  
  // Wait for all tasks to complete
  TTask.WaitForAll(Tasks);
end;

end.
