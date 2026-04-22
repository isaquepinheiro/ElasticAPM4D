{*******************************************************}
{                                                       }
{             Delphi Elastic Apm Agent                  }
{                                                       }
{          Developed by Juliano Eichelberger            }
{                                                       }
{*******************************************************}
unit Apm4D.Share.Stacktrace;

interface

type
  TStacktrace = class
  private
    FAbs_path: String;
    FColno: integer;
    FContext_line: String;
    FFilename: String;
    FFunction: String;
    FLibrary_frame: Boolean;
    FLineno: integer;
    FModule: String;
    FPost_context: TArray<String>;
    FPre_context: TArray<String>;
    Fvars: TObject;
  public
    property Abs_path: String read FAbs_path write FAbs_path;
    property Colno: integer read FColno write FColno;
    property Context_line: String read FContext_line write FContext_line;
    property Filename: String read FFilename write FFilename;
    property &function: String read FFunction write FFunction;
    property Library_frame: Boolean read FLibrary_frame write FLibrary_frame default false;
    property Lineno: integer read FLineno write FLineno;
    property Module: String read FModule write FModule;
    property Post_context: TArray<String> read FPost_context write FPost_context;
    property Pre_context: TArray<String> read FPre_context write FPre_context;
    property Vars: TObject read Fvars write Fvars;
  end;

  TStackTracer = class abstract
  protected
     FStackTrace: TArray<TStacktrace>;
  public
     constructor Create; virtual;
     destructor Destroy; override;
     function Get: TArray<TStacktrace>; virtual;
     function GetCulprit: string; virtual; abstract;
  end;

  TStackTracerClass = class of TStackTracer;

  TStackTracerFactory = reference to function: TStackTracer;

implementation

{ TStackTracer }

constructor TStackTracer.Create;
begin
  // Base initialization if needed
end;

destructor TStackTracer.Destroy;
var
  LStack: TStacktrace;
begin
  for LStack in FStackTrace do
    LStack.Free;
  inherited;
end;

function TStackTracer.Get: TArray<TStacktrace>;
begin
  Result := FStackTrace;
end;

end.
