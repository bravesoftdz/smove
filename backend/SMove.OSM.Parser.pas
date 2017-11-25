unit SMove.OSM.Parser;

interface

uses System.Generics.Collections,
     System.Types,
     System.SysUtils,
     System.Math,
     Xml.XmlDoc,
     XML.XmlIntf,
     Xml.OmniXMLDom,
     Xml.Xmldom,
     Smove.Data.Prolog.Utils;

type
  TOSMParser = class
    private
      FXML: IXMLDocument;
      FResult: TList<TRoadElement>;
      FNodeIds: TDictionary<string, TRoadElement>;
      procedure ProcessWay(AWay: IXMLNode);
      procedure SaveWayForSecondStep(AWay: IXMLNode);
      procedure ProcessTag(ATag: IXMLNode; ARoad: TRoadElement);
      procedure ProcessNode(ANode: IXMLNode);
    public
      constructor Create;
      function Parse(AFilename: string): TList<TRoadElement>;
      destructor Destroy; override;
  end;

implementation

constructor TOSMParser.Create;
begin
  FXML := TXMLDocument.Create(nil);
  (FXML as TXMLDocument).DOMVendor := DOMVendors.Find(sOmniXmlVendor);
end;

procedure TOSMParser.ProcessWay(AWay: IXMLNode);
var Tag: IXMLNode;
    i: integer;
begin
  for i:=0 to AWay.ChildNodes.Count-1 do
  begin
    Tag := AWay.ChildNodes.Get(i);
    if Tag.HasAttribute('k') then
      if Tag.Attributes['k']='highway' then
        begin
          SaveWayForSecondStep(AWay);
          break;
        end;
  end;
end;

procedure TOSMParser.SaveWayForSecondStep(AWay: IXMLNode);
var Tag: IXMLNode;
    i: integer;
    NewRoad: TRoadElement;
begin
  for i:=0 to AWay.ChildNodes.Count-1 do
  begin
    Tag := AWay.ChildNodes.Get(i);
    if Tag.HasAttribute('k') then
      begin
        ProcessTag(Tag,NewRoad);
      end;
  end;
end;

procedure TOSMParser.ProcessTag(ATag: IXMLNode; ARoad: TRoadElement);
var s: string;
begin
  if ATag.Attributes['k'] = 'highway' then
      ARoad.Kind.FromString(ATag.Attributes['v']);
  if ATag.Attributes['k'] = 'surface' then
    begin
      if ATag.Attributes['v'] = 'paved' then
        ARoad.Surface := sfPaved;
      if ATag.Attributes['v'] = 'asphalt' then
        ARoad.Surface := sfAsphalt;
      if ATag.Attributes['v'] = 'sett' then
        ARoad.Surface := sfSett;
      if ATag.Attributes['v'] = 'concrete' then
        ARoad.Surface := sfConcrete;
      if ATag.Attributes['v'] = 'paving_stones' then
        ARoad.Surface := sfPavingStones;
      if ATag.Attributes['v'] = 'cobblestone' then
        ARoad.Surface := sfCobblestone;
      if ATag.Attributes['v'] = 'metal' then
        ARoad.Surface := sfMetal;
      if ATag.Attributes['v'] = 'wood' then
        ARoad.Surface := sfWood;
      if ATag.Attributes['v'] = 'unpaved' then
        ARoad.Surface := sfUnpaved;
      if ATag.Attributes['v'] = 'compacted' then
        ARoad.Surface := sfCompacted;
      if ATag.Attributes['v'] = 'dirt' then
        ARoad.Surface := sfDirt;
      if ATag.Attributes['v'] = 'earth' then
        ARoad.Surface := sfEarth;
      if ATag.Attributes['v'] = 'grass_paver' then
        ARoad.Surface := sfGrassPaver;
      if ATag.Attributes['v'] = 'gravel_turf' then
        ARoad.Surface := sfGravelTurf;
      if ATag.Attributes['v'] = 'sand' then
        ARoad.Surface := sfSand;
    end;
  if (ATag.Attributes['k'] = 'sidewalk:right:width') or
  (ATag.Attributes['k'] = 'sidewalk:left:width') or
  (ATag.Attributes['k'] = 'sidewalk:both:width') then
    ARoad.Width := ATag.Attributes['v'];

  if (ATag.Attributes['k'] = 'sidewalk:right:incline') or
  (ATag.Attributes['k'] = 'sidewalk:left:incline') or
  (ATag.Attributes['k'] = 'sidewalk:both:incline') then
    begin
      if ATag.Attributes['v'] = 'up' then
        ARoad.Slope := slUp;
      if ATag.Attributes['v'] = 'down' then
        ARoad.Slope := slDown;
      s := ATag.Attributes['v'];
      if s[Length(s)] in ['%','°'] then
      begin
        ARoad.Slope := TSlope(Sign(s.TrimRight(['%','°',' ']).ToDouble));
      end;
    end;
end;

function TOSMParser.Parse(AFilename: string): TList<TRoadElement>;
var i: integer;
    Way, Node: IXMLNode;
    b: set of byte;
begin
  FNodeIds := TDictionary<string,TRoadElement>.Create;
  FResult := TList<TRoadElement>.Create;
  FXML.LoadFromFile(AFilename);

  //Process ways
  for i:=0 to FXML.DocumentElement.ChildNodes.Count-1 do
  begin
    Way := FXML.DocumentElement.ChildNodes.Get(i);
    if Way.NodeName = 'way' then
      ProcessWay(Way);
  end;

  //ProcessNodes
  for i:=0 to FXML.DocumentElement.ChildNodes.Count-1 do
  begin
    Node := FXML.DocumentElement.ChildNodes.Get(i);
    if Node.NodeName = 'node' then
      ProcessNode(Node);
  end;

  Result := FResult;
  FResult := nil;
  FreeAndNil(FNodeIds);
end;

procedure TOSMParser.ProcessNode(ANode: IXMLNode);
var Coord: TPointF;
begin
   //Latitude
  Coord.X := ANode.Attributes['lat'];
  //Longtitude
  Coord.Y := ANode.Attributes['lon'];
end;

destructor TOSMParser.Destroy;
begin
  FXML := nil;
end;

end.
