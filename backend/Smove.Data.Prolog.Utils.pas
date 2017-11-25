unit Smove.Data.Prolog.Utils;

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.Types,
  System.Win.Registry,
  Winapi.Windows,
  JvCreateProcess;

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

  TEndPoints = array [0 .. 1] of TPointF;

  TRoadKind = (rkMotorway, rkTrunk, rkPrimary, rkSecondary, rkTertiary,
    rkUnclassified, rkResidential, rkService, rkFootway, rkBridleway, rkSteps,
    rkPath, rkCycleway, rkPedestrain);

  TRoadKindHelper = record helper for TRoadKind
  protected const
    ValueStrings: array [TRoadKind] of String = ('motorway', 'trunk', 'primary',
      'secondary', 'tertiary', 'unclassified', 'residential', 'service',
      'footway', 'bridleway', 'steps', 'path', 'cycleway', 'pedestrian');
  public
    function ToString: String;
    class function FromString(const S: String): TRoadKind; static;
  end;

  TSurface = (sfPaved, sfAsphalt, sfSett, sfConcrete, sfPavingStones,
    sfCobbleStone, sfMetal, sfWood, sfUnpaved, sfCompacted, sfDirt, sfEarth,
    sfGrassPaver, sfGravelTurf, sfSand);

  TDanger = (daHole, daCurbstone, daRoot, daDeer, daRockFall);

  TDangers = set of TDanger;

  TSlope = (slDown = -1, slEven = 0, slUp = 1);

  TRoadElement = record
  private
    FKind: TRoadKind;
    FSurface: TSurface;
    FEndPoints: TEndPoints;
    FDangers: TDangers;
    FLength: Double;
    FWidth: Double;
    FSlope: TSlope;
  public
    property Kind: TRoadKind read FKind write FKind;
    property Surface: TSurface read FSurface write FSurface;
    property EndPoints: TEndPoints read FEndPoints write FEndPoints;
    property Dangers: TDangers read FDangers write FDangers;
    property Length: Double read FLength write FLength;
    property Width: Double read FWidth write FWidth;
    property Slope: TSlope read FSlope write FSlope;
    constructor Create(const AKind: TRoadKind; const ASurface: TSurface;
      const AEndPoints: TEndPoints; const ADangers: TDangers;
      const ALength, AWidth: Double; const ASlope: TSlope);
  end;

  TPrologMapData = class
  private
    FFileName: String;
    FFactsFile: TextFile;
    procedure SetElements(const Value: TArray<TRoadElement>);
  protected
    property FactsFile: TextFile read FFactsFile;
    procedure Initialize; virtual;
    procedure Deinitialize; virtual;
    procedure WriteDependency(const AFileName: String);
    procedure WriteFact(const APredicate: String;
      const AArguments: TArray<String>);
    procedure WriteRule(const AName: String; const AArguments: TArray<String>;
      const ADefinition: String);
  public
    property FileName: String read FFileName;
    property Elements: TArray<TRoadElement> write SetElements;
    constructor Create(const AFileName: String; const ADependencies: TArray<String>);
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

{ TRoadKindHelper }

function TRoadKindHelper.ToString: String;
begin
  Result := ValueStrings[Self];
end;

class function TRoadKindHelper.FromString(const S: String): TRoadKind;
begin
  try
    Result := TRoadKind(IndexStr(S, ValueStrings));
  except
    Result := rkUnclassified;
  end;
end;

{ TRoadElement }

constructor TRoadElement.Create(const AKind: TRoadKind;
  const ASurface: TSurface; const AEndPoints: TEndPoints;
  const ADangers: TDangers; const ALength, AWidth: Double;
  const ASlope: TSlope);
begin
  FKind := AKind;
  FSurface := ASurface;
  FEndPoints := AEndPoints;
  FDangers := ADangers;
  FLength := ALength;
  FWidth := AWidth;
  FSlope := ASlope;
end;

{ TPrologMapData }

constructor TPrologMapData.Create(const AFileName: String; const ADependencies: TArray<String>);
var
  Dependency: String;
begin
  inherited Create;
  FFileName := AFileName;
  Initialize;
  for Dependency in ADependencies do
  begin
    WriteDependency(Dependency);
  end;
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

procedure TPrologMapData.SetElements(const Value: TArray<TRoadElement>);
var
  Element: TRoadElement;
begin
  for Element in Value do
  begin
    WriteFact(Element.Kind.ToString, [Ord(Element.Surface).ToString,
      Element.EndPoints[0].X.ToString, Element.EndPoints[0].Y.ToString,
      Element.EndPoints[1].X.ToString, Element.EndPoints[1].Y.ToString,
      Byte(Element.Dangers).ToString, Element.Length.ToString,
      Element.Width.ToString, Ord(Element.Slope).ToString]);
  end;
end;

procedure TPrologMapData.WriteDependency(const AFileName: String);
begin
  WriteLn(FFactsFile, Concat('[', ExtractFileName(AFileName), ']'));
end;

procedure TPrologMapData.WriteFact(const APredicate: String;
  const AArguments: TArray<String>);
begin
  WriteLn(FFactsFile, Concat(APredicate, IfThen(Length(AArguments) <> 0,
    Concat('(', String.Join(',', AArguments), ')')), '.'));
end;

procedure TPrologMapData.WriteRule(const AName: String;
  const AArguments: TArray<String>; const ADefinition: String);
begin
  WriteLn(FFactsFile, Concat(AName, IfThen(Length(AArguments) <> 0,
    Concat('(', String.Join(',', AArguments), ')')), ' :- ', ADefinition, '.'));
end;

end.
