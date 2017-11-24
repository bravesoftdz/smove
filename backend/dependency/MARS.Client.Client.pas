(*
  Copyright 2016, MARS-Curiosity library

  Home: https://github.com/andrea-magni/MARS
*)
unit MARS.Client.Client;

{$I MARS.inc}

interface

uses
  SysUtils, Classes
  , MARS.Core.JSON
  , MARS.Client.Utils

  // Indy
  , IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP
  ;

type
  TMARSHttpVerb = (Get, Put, Post, Head, Delete, Patch);
  TMARSClientErrorEvent = procedure (AResource: TObject;
    AException: Exception; AVerb: TMARSHttpVerb; const AAfterExecute: TMARSClientResponseProc; var AHandled: Boolean) of object;

  {$ifdef DelphiXE2_UP}
    [ComponentPlatformsAttribute(
        pidWin32 or pidWin64
     or pidOSX32
     or pidiOSSimulator
     or pidiOSDevice
    {$ifdef DelphiXE8_UP}
     or pidiOSDevice32 or pidiOSDevice64
    {$endif}
     or pidAndroid)]
  {$endif}
  TMARSClient = class(TComponent)
  private
    FHttpClient: TIdHTTP;
    FMARSEngineURL: string;
    FOnError: TMARSClientErrorEvent;
    function GetRequest: TIdHTTPRequest;
    function GetResponse: TIdHTTPResponse;
    function GetConnectTimeout: Integer;
    function GetReadTimeout: Integer;
    procedure SetConnectTimeout(const Value: Integer);
    procedure SetReadTimeout(const Value: Integer);
    function GetProtocolVersion: TIdHTTPProtocolVersion;
    procedure SetProtocolVersion(const Value: TIdHTTPProtocolVersion);
  protected
    procedure EndorseAuthorization(const AAuthToken: string);
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure DoError(const AResource: TObject; const AException: Exception; const AVerb: TMARSHttpVerb; const AAfterExecute: TMARSClientResponseProc); virtual;

    procedure Delete(const AURL: string; AResponseContent: TStream; const AAuthToken: string);
    procedure Get(const AURL: string; AResponseContent: TStream; const AAccept: string; const AAuthToken: string);
    procedure Post(const AURL: string; AContent, AResponse: TStream; const AAuthToken: string);
    procedure Put(const AURL: string; AContent, AResponse: TStream; const AAuthToken: string);
    function LastCmdSuccess: Boolean;
    function ResponseText: string;

    property Request: TIdHTTPRequest read GetRequest;
    property Response: TIdHTTPResponse read GetResponse;

    // shortcuts
    class function GetJSON<T: TJSONValue>(const AEngineURL, AAppName, AResourceName: string;
      const AToken: string = ''): T; overload;

    class function GetJSON<T: TJSONValue>(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AToken: string = '';
      const AIgnoreResult: Boolean = False): T; overload;

{$ifdef DelphiXE7_UP}
    class procedure GetJSONAsync<T: TJSONValue>(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const ACompletionHandler: TProc<T>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TMARSClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AToken: string = '';
      const ASynchronize: Boolean = True); overload;
{$endif}

    class function GetAsString(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AToken: string = ''): string; overload;

    class function PostJSON(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AContent: TJSONValue;
      const ACompletionHandler: TProc<TJSONValue>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AToken: string = ''
    ): Boolean;

{$ifdef DelphiXE7_UP}
    class procedure PostJSONAsync(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AContent: TJSONValue;
      const ACompletionHandler: TProc<TJSONValue>{$ifdef DelphiXE2_UP} = nil{$endif};
      const AOnException: TMARSClientExecptionProc{$ifdef DelphiXE2_UP} = nil{$endif};
      const AToken: string = '';
      const ASynchronize: Boolean = True);
{$endif}

    class function GetStream(const AEngineURL, AAppName, AResourceName: string;
      const AToken: string = ''): TStream; overload;

    class function GetStream(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AToken: string = ''): TStream; overload;

    class function PostStream(const AEngineURL, AAppName, AResourceName: string;
      const APathParams: TArray<string>; const AQueryParams: TStrings;
      const AContent: TStream; const AToken: string = ''): Boolean;

  published
    property MARSEngineURL: string read FMARSEngineURL write FMARSEngineURL;
    property ConnectTimeout: Integer read GetConnectTimeout write SetConnectTimeout;
    property ReadTimeout: Integer read GetReadTimeout write SetReadTimeout;
    property OnError: TMARSClientErrorEvent read FOnError write FOnError;
    property ProtocolVersion: TIdHTTPProtocolVersion read GetProtocolVersion write SetProtocolVersion;
    property HttpClient: TIdHTTP read FHttpClient;
  end;

function TMARSHttpVerbToString(const AVerb: TMARSHttpVerb): string;

procedure Register;

implementation

uses
    Rtti, TypInfo
  , MARS.Client.CustomResource
  , MARS.Client.Resource
  , MARS.Client.Resource.JSON
  , MARS.Client.Resource.Stream
  , MARS.Client.Application
;

procedure Register;
begin
  RegisterComponents('MARS-Curiosity Client', [TMARSClient]);
end;

function TMARSHttpVerbToString(const AVerb: TMARSHttpVerb): string;
begin
{$ifdef DelphiXE7_UP}
  Result := TRttiEnumerationType.GetName<TMARSHttpVerb>(AVerb);
{$else}
  Result := GetEnumName(TypeInfo(TMARSHttpVerb), Integer(AVerb));
{$endif}
end;

{ TMARSClient }

procedure TMARSClient.AssignTo(Dest: TPersistent);
var
  LDestClient: TMARSClient;
begin
//  inherited;
  LDestClient := Dest as TMARSClient;

  LDestClient.MARSEngineURL := MARSEngineURL;
  LDestClient.ConnectTimeout := ConnectTimeout;
  LDestClient.ReadTimeout := ReadTimeout;
  LDestClient.OnError := OnError;
  LDestClient.ProtocolVersion := ProtocolVersion;
end;

constructor TMARSClient.Create(AOwner: TComponent);
begin
  inherited;
  FHttpClient := TIdHTTP.Create(Self);
  try
    FHttpClient.SetSubComponent(True);
    FHttpClient.Name := 'HttpClient';
  except
    FHttpClient.Free;
    raise;
  end;
  FMARSEngineURL := 'http://localhost:8080/rest';
end;


procedure TMARSClient.Delete(const AURL: string; AResponseContent: TStream; const AAuthToken: string);
begin
  EndorseAuthorization(AAuthToken);
{$ifdef DelphiXE7_UP}
  FHttpClient.Delete(AURL, AResponseContent);
{$else}
  FHttpClient.Delete(AURL{, AResponseContent});
{$endif}
end;

destructor TMARSClient.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

procedure TMARSClient.DoError(const AResource: TObject;
  const AException: Exception; const AVerb: TMARSHttpVerb;
  const AAfterExecute: TMARSClientResponseProc);
var
  LHandled: Boolean;
begin
  LHandled := False;

  if Assigned(FOnError) then
    FOnError(AResource, AException, AVerb, AAfterExecute, LHandled);

  if not LHandled then
    raise EMARSClientException.Create(AException.Message)
end;

procedure TMARSClient.EndorseAuthorization(const AAuthToken: string);
begin
  if not (AAuthToken = '') then
  begin
    FHttpClient.Request.CustomHeaders.FoldLines := False;
    FHttpClient.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + AAuthToken;
  end
  else
    FHttpClient.Request.CustomHeaders.Values['Authorization'] := '';
end;

procedure TMARSClient.Get(const AURL: string; AResponseContent: TStream;
  const AAccept: string; const AAuthToken: string);
begin
  FHttpClient.Request.Accept := AAccept;
  EndorseAuthorization(AAuthToken);
  FHttpClient.Get(AURL, AResponseContent);
end;

function TMARSClient.GetConnectTimeout: Integer;
begin
  Result := FHttpClient.ConnectTimeout;
end;

function TMARSClient.GetReadTimeout: Integer;
begin
  Result := FHttpClient.ReadTimeout;
end;

function TMARSClient.GetRequest: TIdHTTPRequest;
begin
  Result := FHttpClient.Request;
end;

function TMARSClient.GetResponse: TIdHTTPResponse;
begin
  Result := FHttpClient.Response;
end;

function TMARSClient.LastCmdSuccess: Boolean;
begin
  Result := FHttpClient.ResponseCode = 200;
end;

procedure TMARSClient.Post(const AURL: string; AContent, AResponse: TStream; const AAuthToken: string);
begin
  EndorseAuthorization(AAuthToken);
  FHttpClient.Post(AURL, AContent, AResponse);
end;

procedure TMARSClient.Put(const AURL: string; AContent, AResponse: TStream; const AAuthToken: string);
begin
  EndorseAuthorization(AAuthToken);
  FHttpClient.Put(AURL, AContent, AResponse);
end;

function TMARSClient.ResponseText: string;
begin
  Result := FHttpClient.ResponseText;
end;

procedure TMARSClient.SetConnectTimeout(const Value: Integer);
begin
  FHttpClient.ConnectTimeout := Value;
end;

procedure TMARSClient.SetProtocolVersion(const Value: TIdHTTPProtocolVersion);
begin
  FHttpClient.ProtocolVersion := Value;
end;

procedure TMARSClient.SetReadTimeout(const Value: Integer);
begin
  FHttpClient.ReadTimeout := Value;
end;

class function TMARSClient.GetAsString(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AToken: string): string;
var
  LClient: TMARSClient;
  LResource: TMARSClientResource;
  LApp: TMARSClientApplication;
  LIndex: Integer;
  LFinalURL: string;
begin
  LClient := TMARSClient.Create(nil);
  try
    LClient.MARSEngineURL := AEngineURL;
    LApp := TMARSClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TMARSClientResource.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LFinalURL := LResource.URL;
        LResource.SpecificToken := AToken;
        Result := LResource.GETAsString();
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;

class function TMARSClient.GetJSON<T>(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AToken: string; const AIgnoreResult: Boolean): T;
var
  LClient: TMARSClient;
  LResource: TMARSClientResourceJSON;
  LApp: TMARSClientApplication;
  LIndex: Integer;
  LFinalURL: string;
begin
  Result := nil;
  LClient := TMARSClient.Create(nil);
  try
    LClient.MARSEngineURL := AEngineURL;
    LApp := TMARSClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TMARSClientResourceJSON.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LFinalURL := LResource.URL;
        LResource.SpecificToken := AToken;
        LResource.GET(nil, nil, nil);

        Result := nil;
        if not AIgnoreResult then
          Result := LResource.Response.Clone as T;
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;

{$ifdef DelphiXE7_UP}
class procedure TMARSClient.GetJSONAsync<T>(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const ACompletionHandler: TProc<T>;
  const AOnException: TMARSClientExecptionProc; const AToken: string;
  const ASynchronize: Boolean);
var
  LClient: TMARSClient;
  LResource: TMARSClientResourceJSON;
  LApp: TMARSClientApplication;
  LIndex: Integer;
  LFinalURL: string;
begin
  LClient := TMARSClient.Create(nil);
  try
    LClient.MARSEngineURL := AEngineURL;
    LApp := TMARSClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TMARSClientResourceJSON.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LFinalURL := LResource.URL;
        LResource.SpecificToken := AToken;
        LResource.GETAsync(
          procedure (AResource: TMARSClientCustomResource)
          begin
            try
              if Assigned(ACompletionHandler) then
                ACompletionHandler((AResource as TMARSClientResourceJSON).Response as T);
            finally
              LResource.Free;
              LApp.Free;
              LClient.Free;
            end;
          end
        , AOnException
        , ASynchronize
        );
        except
          LResource.Free;
          raise;
        end;
      except
        LApp.Free;
        raise;
      end;
    except
      LClient.Free;
      raise;
    end;
end;
{$endif}

function TMARSClient.GetProtocolVersion: TIdHTTPProtocolVersion;
begin
  Result := FHttpClient.ProtocolVersion;
end;

class function TMARSClient.GetStream(const AEngineURL, AAppName,
  AResourceName: string; const AToken: string): TStream;
begin
  Result := GetStream(AEngineURL, AAppName, AResourceName, nil, nil, AToken);
end;

class function TMARSClient.GetJSON<T>(const AEngineURL, AAppName,
  AResourceName: string; const AToken: string): T;
begin
  Result := GetJSON<T>(AEngineURL, AAppName, AResourceName, nil, nil, AToken);
end;

class function TMARSClient.GetStream(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AToken: string): TStream;
var
  LClient: TMARSClient;
  LResource: TMARSClientResourceStream;
  LApp: TMARSClientApplication;
  LIndex: Integer;
begin
  LClient := TMARSClient.Create(nil);
  try
    LClient.MARSEngineURL := AEngineURL;
    LApp := TMARSClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TMARSClientResourceStream.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LResource.SpecificToken := AToken;
        LResource.GET(nil, nil, nil);

        Result := TMemoryStream.Create;
        try
          Result.CopyFrom(LResource.Response, LResource.Response.Size);
        except
          Result.Free;
          raise;
        end;
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;

class function TMARSClient.PostJSON(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>; const AQueryParams: TStrings;
  const AContent: TJSONValue; const ACompletionHandler: TProc<TJSONValue>; const AToken: string
): Boolean;
var
  LClient: TMARSClient;
  LResource: TMARSClientResourceJSON;
  LApp: TMARSClientApplication;
  LIndex: Integer;
begin
  LClient := TMARSClient.Create(nil);
  try
    LClient.MARSEngineURL := AEngineURL;
    LApp := TMARSClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TMARSClientResourceJSON.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LResource.SpecificToken := AToken;
        LResource.POST(
          procedure (AStream: TMemoryStream)
          var
            LWriter: TStreamWriter;
          begin
            if Assigned(AContent) then
            begin
              LWriter := TStreamWriter.Create(AStream);
              try
                LWriter.Write(AContent.ToJSON);
              finally
                LWriter.Free;
              end;
            end;
          end
        , procedure (AStream: TStream)
          begin
            if Assigned(ACompletionHandler) then
              ACompletionHandler(LResource.Response);
          end
        , nil
        );
        Result := LClient.Response.ResponseCode = 200;
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;


{$ifdef DelphiXE7_UP}
class procedure TMARSClient.PostJSONAsync(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AContent: TJSONValue;
  const ACompletionHandler: TProc<TJSONValue>;
  const AOnException: TMARSClientExecptionProc;
  const AToken: string;
  const ASynchronize: Boolean);
var
  LClient: TMARSClient;
  LResource: TMARSClientResourceJSON;
  LApp: TMARSClientApplication;
  LIndex: Integer;
begin
  LClient := TMARSClient.Create(nil);
  try
    LClient.MARSEngineURL := AEngineURL;
    LApp := TMARSClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TMARSClientResourceJSON.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LResource.SpecificToken := AToken;
        LResource.POSTAsync(
          procedure (AStream: TMemoryStream)
          var
            LWriter: TStreamWriter;
          begin
            if Assigned(AContent) then
            begin
              LWriter := TStreamWriter.Create(AStream);
              try
                LWriter.Write(AContent.ToJSON);
              finally
                LWriter.Free;
              end;
            end;
          end
        , procedure (AResource: TMARSClientCustomResource)
          begin
            try
              if Assigned(ACompletionHandler) then
                ACompletionHandler((AResource as TMARSClientResourceJSON).Response);
            finally
              LResource.Free;
              LApp.Free;
              LClient.Free;
            end;
          end
        , AOnException
        , ASynchronize
        );
      except
        LResource.Free;
        raise;
      end;
    except
      LApp.Free;
      raise;
    end;
  except
    LClient.Free;
    raise;
  end;
end;
{$endif}

class function TMARSClient.PostStream(const AEngineURL, AAppName,
  AResourceName: string; const APathParams: TArray<string>;
  const AQueryParams: TStrings; const AContent: TStream; const AToken: string
): Boolean;
var
  LClient: TMARSClient;
  LResource: TMARSClientResourceStream;
  LApp: TMARSClientApplication;
  LIndex: Integer;
begin
  LClient := TMARSClient.Create(nil);
  try
    LClient.MARSEngineURL := AEngineURL;
    LApp := TMARSClientApplication.Create(nil);
    try
      LApp.Client := LClient;
      LApp.AppName := AAppName;
      LResource := TMARSClientResourceStream.Create(nil);
      try
        LResource.Application := LApp;
        LResource.Resource := AResourceName;

        LResource.PathParamsValues.Clear;
        for LIndex := 0 to Length(APathParams)-1 do
          LResource.PathParamsValues.Add(APathParams[LIndex]);

        if Assigned(AQueryParams) then
          LResource.QueryParams.Assign(AQueryParams);

        LResource.SpecificToken := AToken;
        LResource.POST(
          procedure (AStream: TMemoryStream)
          begin
            if Assigned(AContent) then
            begin
              AStream.Size := 0; // reset
              AContent.Position := 0;
              AStream.CopyFrom(AContent, AContent.Size);
            end;
          end
        , nil, nil
        );
        Result := LClient.Response.ResponseCode = 200;
      finally
        LResource.Free;
      end;
    finally
      LApp.Free;
    end;
  finally
    LClient.Free;
  end;
end;


end.
