unit Resources;

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

  end;

implementation

initialization

  TMARSResourceRegistry.Instance.RegisterResource<TBackendResource>;

end.
