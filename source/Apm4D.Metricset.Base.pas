{ ******************************************************* }
{                                                         }
{        Delphi Elastic Apm Agent                         }
{                                                         }
{        Developed by Juliano Eichelberger                }
{                                                         }
{ ******************************************************* }
unit Apm4D.Metricset.Base;

interface

uses
  Apm4D.Metricset.Formatter;

type
  /// <summary>
  /// Base class for all metricsets. 
  /// Inherit from this class to create custom metricsets.
  /// </summary>
  TApm4DMetricsetBase = class abstract
  private
    FFormatter: TMetricsetFormatter;
  protected
    /// <summary>
    /// Override this method to collect your custom metrics.
    /// Add metrics using Formatter.AddXXX methods.
    /// </summary>
    procedure CollectMetrics; virtual; abstract;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    
    /// <summary>
    /// Collects metrics and returns JSON string.
    /// </summary>
    function ToJsonString: string;
    
    /// <summary>
    /// Returns the metricset samples object.
    /// </summary>
    property Formatter: TMetricsetFormatter read FFormatter;
  end;
  
  TApm4DMetricsetClass = class of TApm4DMetricsetBase;

implementation

uses
  System.SysUtils, Apm4D.Share.TimestampEpoch;

{ TApm4DMetricsetBase }

constructor TApm4DMetricsetBase.Create;
begin
  inherited Create;
  FFormatter := TMetricsetFormatter.Create;
end;

destructor TApm4DMetricsetBase.Destroy;
begin
  FFormatter.Free;
  inherited;
end;

function TApm4DMetricsetBase.ToJsonString: string;
const
  JSON_STR = '{"metricset":{"timestamp":%d,%s}}';
begin
  // Clear any previous samples and collect fresh metrics
  FFormatter.Clear;
  CollectMetrics;
  
  // Metricset inherits service information from metadata sent at stream start
  Result := Format(JSON_STR, [TTimestampEpoch.Get(Now), FFormatter.ToJsonString]);
end;

end.
