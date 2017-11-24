unit Smove.Resources;

interface

uses
  MARS.Core.Attributes,
  MARS.Core.MediaType,
  MARS.Core.Registry,
  MARS.Core.MessageBodyReader,
  MARS.Core.MessageBodyReaders,
  System.Classes, System.SysUtils,
  System.JSON;

type
  [Path('/backend')]
  TBackendResource = class
    [GET, Path('/')]
    function Hi: string;
  end;

implementation

function TBackendResource.Hi: string;
begin
  Result := 'Hi!';
end;

initialization

  TMARSResourceRegistry.Instance.RegisterResource<TBackendResource>;

end.
