{ ******************************************************* }
{ }
{ Delphi Elastic Apm Agent }
{ }
{ Developed by Juliano Eichelberger }
{ }
{ ******************************************************* }
unit Apm4D.Metricset.Defaults;

interface

uses
  Winapi.psAPI, Winapi.Windows, System.SysUtils, System.Classes, Apm4D.Metricset.Base;

type
  /// <summary>
  /// Default system metrics metricset.
  /// Collects CPU and Memory metrics.
  /// </summary>
  TApm4DMetricsetSystem = class(TApm4DMetricsetBase)
  private type
    TSystemMemory = record
      TotalPhysical: UInt64;
      AvailablePhysical: UInt64;
      TotalPageFile: UInt64;
      MemoryLoad: Double;
    end;

    TSystemCpu = record
      SystemCpuPct: Double; // System CPU usage [0,1]
      ProcessCpuPct: Double; // Process CPU usage [0,1]
    end;

  private
    FLastSystemIdleTime: TFileTime;
    FLastSystemKernelTime: TFileTime;
    FLastSystemUserTime: TFileTime;
    FLastProcessKernelTime: TFileTime;
    FLastProcessUserTime: TFileTime;
    FLastSampleTime: TDateTime;
    FFirstSample: Boolean;

    function GetSystemMemory: TSystemMemory;
    function GetSystemCpu: TSystemCpu;
  protected
    procedure CollectMetrics; override;
  public
    constructor Create; override;
  end;

  /// <summary>
  /// Process-specific metrics metricset.
  /// Collects process memory and CPU usage following Elastic APM spec.
  /// https://github.com/elastic/apm/blob/main/specs/agents/metrics.md
  /// </summary>
  TApm4DMetricsetProcess = class(TApm4DMetricsetBase)
  private type
    TProcessMemoryInfo = record
      WorkingSetSize: UInt64; // Current working set (physical memory)
      PeakWorkingSetSize: UInt64; // Peak working set
      PrivateUsage: UInt64; // Private bytes (committed memory)
      VirtualSize: UInt64; // Virtual memory size
    end;
  private
    FLastProcessKernelTime: TFileTime;
    FLastProcessUserTime: TFileTime;
    FLastSampleTime: TDateTime;
    FFirstSample: Boolean;

    function GetProcessMemory: TProcessMemoryInfo;
    function GetProcessCpu: Double;
  protected
    procedure CollectMetrics; override;
  public
    constructor Create; override;
  end;

implementation

{$IFDEF MSWINDOWS}


uses
  System.Win.ComObj, System.Variants, Apm4D.Metricset.Formatter;
{$ENDIF}

{ TApm4DMetricsetSystem }

constructor TApm4DMetricsetSystem.Create;
begin
  inherited Create;
  FFirstSample := True;
end;

function TApm4DMetricsetSystem.GetSystemMemory: TSystemMemory;
var
  MemStatus: TMemoryStatusEx;
begin
  FillChar(Result, SizeOf(Result), 0);
  MemStatus.dwLength := SizeOf(TMemoryStatusEx);

  if GlobalMemoryStatusEx(MemStatus) then
  begin
    Result.TotalPhysical := MemStatus.ullTotalPhys;
    Result.AvailablePhysical := MemStatus.ullAvailPhys;
    Result.TotalPageFile := MemStatus.ullTotalPageFile;
    Result.MemoryLoad := MemStatus.dwMemoryLoad;
  end;
end;

function TApm4DMetricsetSystem.GetSystemCpu: TSystemCpu;
var
  SystemIdleTime, SystemKernelTime, SystemUserTime: TFileTime;
  ProcessCreationTime, ProcessExitTime, ProcessKernelTime, ProcessUserTime: TFileTime;
  SystemIdleDiff, SystemKernelDiff, SystemUserDiff, SystemTotalDiff: Int64;
  ProcessKernelDiff, ProcessUserDiff, ProcessTotalDiff: Int64;
  CurrentTime: TDateTime;
  TimeDiff: Double;
begin
  Result.SystemCpuPct := 0;
  Result.ProcessCpuPct := 0;

  CurrentTime := Now;

  // Get system times
  if not GetSystemTimes(SystemIdleTime, SystemKernelTime, SystemUserTime) then
    Exit;

  // Get process times
  if not GetProcessTimes(GetCurrentProcess, ProcessCreationTime, ProcessExitTime,
    ProcessKernelTime, ProcessUserTime) then
    Exit;

  // First sample - just store values
  if FFirstSample then
  begin
    FLastSystemIdleTime := SystemIdleTime;
    FLastSystemKernelTime := SystemKernelTime;
    FLastSystemUserTime := SystemUserTime;
    FLastProcessKernelTime := ProcessKernelTime;
    FLastProcessUserTime := ProcessUserTime;
    FLastSampleTime := CurrentTime;
    FFirstSample := False;
    Exit;
  end;

  TimeDiff := (CurrentTime - FLastSampleTime) * 24 * 3600; // seconds

  // Avoid division by zero or too short intervals
  if TimeDiff < 0.1 then
    Exit;

  // Calculate system CPU usage
  SystemIdleDiff := Int64(SystemIdleTime) - Int64(FLastSystemIdleTime);
  SystemKernelDiff := Int64(SystemKernelTime) - Int64(FLastSystemKernelTime);
  SystemUserDiff := Int64(SystemUserTime) - Int64(FLastSystemUserTime);
  SystemTotalDiff := SystemKernelDiff + SystemUserDiff;

  if SystemTotalDiff > 0 then
    Result.SystemCpuPct := (SystemTotalDiff - SystemIdleDiff) / SystemTotalDiff;

  // Calculate process CPU usage
  ProcessKernelDiff := Int64(ProcessKernelTime) - Int64(FLastProcessKernelTime);
  ProcessUserDiff := Int64(ProcessUserTime) - Int64(FLastProcessUserTime);
  ProcessTotalDiff := ProcessKernelDiff + ProcessUserDiff;

  // Convert 100-nanosecond intervals to percentage of time elapsed
  if TimeDiff > 0 then
    Result.ProcessCpuPct := (ProcessTotalDiff / 10000000.0) / TimeDiff;

  // Clamp values to [0,1] range
  if Result.SystemCpuPct < 0 then
    Result.SystemCpuPct := 0;
  if Result.SystemCpuPct > 1 then
    Result.SystemCpuPct := 1;
  if Result.ProcessCpuPct < 0 then
    Result.ProcessCpuPct := 0;
  if Result.ProcessCpuPct > 1 then
    Result.ProcessCpuPct := 1;

  // Store current values for next calculation
  FLastSystemIdleTime := SystemIdleTime;
  FLastSystemKernelTime := SystemKernelTime;
  FLastSystemUserTime := SystemUserTime;
  FLastProcessKernelTime := ProcessKernelTime;
  FLastProcessUserTime := ProcessUserTime;
  FLastSampleTime := CurrentTime;
end;

procedure TApm4DMetricsetSystem.CollectMetrics;
var
  Memory: TSystemMemory;
  Cpu: TSystemCpu;
begin
  inherited;
  Memory := GetSystemMemory;
  Cpu := GetSystemCpu;

  // Elastic APM official metric names - must be in BYTES as per specification:
  // https://github.com/elastic/apm/blob/main/specs/agents/metrics.md
  Formatter.AddBytesGauge('system.memory.total', Memory.TotalPhysical);
  Formatter.AddBytesGauge('system.memory.actual.free', Memory.AvailablePhysical);

  // CPU metrics (in range [0,1] representing 0-100%)
  if (Cpu.SystemCpuPct > 0) or (Cpu.ProcessCpuPct > 0) then
  begin
    Formatter.AddDecimalGauge('system.cpu.total.norm.pct', Cpu.SystemCpuPct);
    Formatter.AddDecimalGauge('system.process.cpu.total.norm.pct', Cpu.ProcessCpuPct);
  end;
end;

{ TApm4DMetricsetProcess }

constructor TApm4DMetricsetProcess.Create;
begin
  inherited Create;
  FFirstSample := True;
end;

function TApm4DMetricsetProcess.GetProcessMemory: TProcessMemoryInfo;
var
  MemCounters: TProcessMemoryCountersEx;
begin
  FillChar(Result, SizeOf(Result), 0);
  FillChar(MemCounters, SizeOf(MemCounters), 0);
  MemCounters.cb := SizeOf(TProcessMemoryCountersEx);

  if GetProcessMemoryInfo(GetCurrentProcess, @MemCounters, MemCounters.cb) then
  begin
    Result.WorkingSetSize := MemCounters.WorkingSetSize;
    Result.PeakWorkingSetSize := MemCounters.PeakWorkingSetSize;
    Result.PrivateUsage := MemCounters.PrivateUsage;
    Result.VirtualSize := MemCounters.PagefileUsage;
  end;
end;

function TApm4DMetricsetProcess.GetProcessCpu: Double;
var
  ProcessCreationTime, ProcessExitTime, ProcessKernelTime, ProcessUserTime: TFileTime;
  ProcessKernelDiff, ProcessUserDiff, ProcessTotalDiff: Int64;
  CurrentTime: TDateTime;
  TimeDiff: Double;
begin
  Result := 0;
  CurrentTime := Now;

  // Get process times
  if not GetProcessTimes(GetCurrentProcess, ProcessCreationTime, ProcessExitTime,
    ProcessKernelTime, ProcessUserTime) then
    Exit;

  // First sample - just store values
  if FFirstSample then
  begin
    FLastProcessKernelTime := ProcessKernelTime;
    FLastProcessUserTime := ProcessUserTime;
    FLastSampleTime := CurrentTime;
    FFirstSample := False;
    Exit;
  end;

  TimeDiff := (CurrentTime - FLastSampleTime) * 24 * 3600; // seconds

  // Avoid division by zero or too short intervals
  if TimeDiff < 0.1 then
    Exit;

  // Calculate process CPU usage
  ProcessKernelDiff := Int64(ProcessKernelTime) - Int64(FLastProcessKernelTime);
  ProcessUserDiff := Int64(ProcessUserTime) - Int64(FLastProcessUserTime);
  ProcessTotalDiff := ProcessKernelDiff + ProcessUserDiff;

  // Convert 100-nanosecond intervals to percentage of time elapsed
  if TimeDiff > 0 then
    Result := (ProcessTotalDiff / 10000000.0) / TimeDiff;

  // Clamp values to [0,1] range
  if Result < 0 then
    Result := 0;
  if Result > 1 then
    Result := 1;

  // Store current values for next calculation
  FLastProcessKernelTime := ProcessKernelTime;
  FLastProcessUserTime := ProcessUserTime;
  FLastSampleTime := CurrentTime;
end;

procedure TApm4DMetricsetProcess.CollectMetrics;
var
  ProcessMem: TProcessMemoryInfo;
  CpuUsage: Double;
begin
  inherited;
  ProcessMem := GetProcessMemory;
  CpuUsage := GetProcessCpu;

  // Elastic APM official process metrics (in bytes):
  // https://github.com/elastic/apm/blob/main/specs/agents/metrics.md
  Formatter.AddBytesGauge('system.process.memory.size', ProcessMem.WorkingSetSize);
  Formatter.AddBytesGauge('system.process.memory.rss.bytes', ProcessMem.WorkingSetSize);

  // Additional useful metrics (not in official spec but useful for Windows)
  Formatter.AddBytesGauge('system.process.memory.private.bytes', ProcessMem.PrivateUsage);
  Formatter.AddBytesGauge('system.process.memory.virtual.bytes', ProcessMem.VirtualSize);

  // CPU usage for process (in range [0,1])
  if CpuUsage > 0 then
  begin
    Formatter.AddDecimalGauge('system.process.cpu.total.norm.pct', CpuUsage);
  end;
end;

end.
