program BackendProject;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Types,
  Smove.Server.Resources in 'Smove.Server.Resources.pas',
  MARS.HTTP.Server.Indy,
  MARS.Core.Engine,
  MARS.Core.Application,
  Smove.Data.Prolog.Utils in 'Smove.Data.Prolog.Utils.pas',
  SMove.OSM.Parser in 'SMove.OSM.Parser.pas';

type
  TServer = class
  private
    FEngine: TMARSEngine;
    FServer: TMARShttpServerIndy;
  public
    constructor Create;
    property Server: TMARShttpServerIndy read FServer;
    property Engine: TMARSEngine read FEngine;
  end;

{ TServer }

constructor TServer.Create;
begin
  FEngine := TMARSEngine.Create;
  try
    Engine.Port := 80;
    Engine.ThreadPoolSize := 4;
    Engine.AddApplication('Smove', '/smove',['Smove.Server.Resources.*']);
    FServer := TMARShttpServerIndy.Create(Engine);
    try
      Server.DefaultPort := Engine.Port;
      Server.Active := True;
    except
      Server.Free;
      raise;
    end;
  except
    Engine.Free;
    raise;
  end;
end;

var
  Server: TServer;
begin
  try
    Server := TServer.Create;
    try
      repeat
        // :)
      until (False);
    finally
      Server.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
