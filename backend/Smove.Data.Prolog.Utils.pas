unit Smove.Data.Prolog.Utils;

interface

uses
  System.Types,
  System.Win.Registry,
  Winapi.Windows,
  JvCreateProcess;

const
  NumberOfEndPoints = 2;

type
  TPrologApplication = class
  private
    FExeName: String;
    FFactsFileName: String;
    FCreateProcess: TJvCreateProcess;
    function GetAsk(const AQuery: String): TArray<String>;
  protected
    property CreateProcess: TJvCreateProcess read FCreateProcess;
    procedure Initialize; virtual;
    procedure Deinitialize; virtual;
  public
    property ExeName: String read FExeName;
    property FactsFileName: String read FFactsFileName;
    property Ask[const AQuery: String]: TArray<String> read GetAsk;
    constructor Create(const AFactFileName: String);
    destructor Destroy; override;
  end;

  TEndPoints = array [0 .. Pred(NumberOfEndPoints)] of TPointF;

  TRoadKind = (rkMotorway, rkTrunk, rkPrimary, rkSecondary, rkTertiary,
    rkUnclassified, rkResidential, rkService, rkFootway, rkBridleway, rkSteps,
    rkPath, rkCycleway);

  TSurface = (sfPaved, sfAsphalt, sfSett, sfConcrete, sfPavingStones,
    sfCobbleStone, sfMetal, sfWood, sfUnpaved, sfCompacted, sfDirt, sfEarth,
    sfGrassPaver, sfGravelTurf, sfSand);

  TDanger = (daHole, daCurbstone, daRoot, daDeer, daRockFall);

  TDangers = set of TDanger;

  TSlope = (slUp = 1, slDown = -1);

  TRoadElement = record
  public
    FKind: TRoadKind;
    FSurface: TSurface;
    FEndPoints: TEndPoints;
    FDangers: TDangers;
    FWidth: Double;
    FSlope: TSlope;
  public
    property Kind: TRoadKind read FKind;
    property Surface: TSurface read FSurface;
    property EndPoints: TEndPoints read FEndPoints;
    property Dangers: TDangers read FDangers;
    property Width: Double read FWidth;
    property Slope: TSlope read FSlope;
    constructor Create(const AKind: TRoadKind; const ASurface: TSurface;
      const AEndPoints: TEndPoints; const ADangers: TDangers;
      const AWidth: Double; const ASlope: TSlope);
  end;

  TPrologMapData = class
  private
    FFileName: String;
    FFactsFile: TextFile;
  protected
    property FactsFile: TextFile read FFactsFile;
    procedure Initialize; virtual;
    procedure Deinitialize; virtual;
  public
    property FileName: String read FFileName;
    constructor Create(const AFileName: String);
    destructor Destroy; override;

  end;

implementation

{ TPrologApplication }

constructor TPrologApplication.Create(const AFactFileName: String);
begin
  inherited Create;
  FFactsFileName := AFactFileName;
  Initialize;
end;

procedure TPrologApplication.Deinitialize;
begin
  FCreateProcess.Free;
end;

destructor TPrologApplication.Destroy;
begin
  Deinitialize;
  inherited;
end;

function TPrologApplication.GetAsk(const AQuery: String): TArray<String>;
begin
  FCreateProcess.ConsoleOutput.Clear;
  FCreateProcess.Run;
  FCreateProcess.WriteLn(AQuery);
  Result := FCreateProcess.ConsoleOutput.ToStringArray;
end;

procedure TPrologApplication.Initialize;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    Registry.OpenKey('SOFTWARE\SWI\Prolog', False);
    FExeName := Registry.ReadString(Concat('home', 'bin\swipl.exe'));
  finally
    Registry.Free;
  end;
  FCreateProcess := TJvCreateProcess.Create(nil);
  FCreateProcess.ApplicationName := ExeName;
  FCreateProcess.CommandLine := FactsFileName;
end;

{ TRoadElement }

constructor TRoadElement.Create(const AKind: TRoadKind;
  const ASurface: TSurface; const AEndPoints: TEndPoints;
  const ADangers: TDangers; const AWidth: Double; const SSlope: TSlope);
begin
  FKind := AKind;
  FSurface := ASurface;
  FEndPoints := AEndPoints;
  FDangers := ADangers;
  FWidth := AWidth;
  FSlope := ASlope;
end;

{ TPrologMapData }

constructor TPrologMapData.Create(const AFileName: String);
begin
  inherited Create;
  FFileName := AFileName;
  Initialize;
end;

procedure TPrologMapData.Deinitialize;
begin
  CloseFile(FFactsFile);
end;

destructor TPrologMapData.Destroy;
begin
  Deinitialize;
  inherited;
end;

procedure TPrologMapData.Initialize;
begin
  AssignFile(FFactsFile, FileName);
  Rewrite(FFactsFile);
end;

end.
