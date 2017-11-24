program BackendProject;

{$APPTYPE CONSOLE}

{$R *.res}



uses
  System.SysUtils,
  MARS.Client.Utils.LiveBindings in 'dependency\MARS.Client.Utils.LiveBindings.pas',
  MARS.Client.Utils in 'dependency\MARS.Client.Utils.pas',
  MARS.Core.Activation.InjectionService in 'dependency\MARS.Core.Activation.InjectionService.pas',
  MARS.Core.Activation.Interfaces in 'dependency\MARS.Core.Activation.Interfaces.pas',
  MARS.Core.Activation in 'dependency\MARS.Core.Activation.pas',
  MARS.Core.Application in 'dependency\MARS.Core.Application.pas',
  MARS.Core.Attributes in 'dependency\MARS.Core.Attributes.pas',
  MARS.Core.Cache in 'dependency\MARS.Core.Cache.pas',
  MARS.Core.Classes in 'dependency\MARS.Core.Classes.pas',
  MARS.Core.Declarations in 'dependency\MARS.Core.Declarations.pas',
  MARS.Core.Engine in 'dependency\MARS.Core.Engine.pas',
  MARS.Core.Exceptions in 'dependency\MARS.Core.Exceptions.pas',
  MARS.Core.Injection.Interfaces in 'dependency\MARS.Core.Injection.Interfaces.pas',
  MARS.Core.Injection in 'dependency\MARS.Core.Injection.pas',
  MARS.Core.Injection.Types in 'dependency\MARS.Core.Injection.Types.pas',
  MARS.Core.JSON in 'dependency\MARS.Core.JSON.pas',
  MARS.Core.MediaType in 'dependency\MARS.Core.MediaType.pas',
  MARS.Core.MessageBodyReader in 'dependency\MARS.Core.MessageBodyReader.pas',
  MARS.Core.MessageBodyReaders in 'dependency\MARS.Core.MessageBodyReaders.pas',
  MARS.Core.MessageBodyWriter in 'dependency\MARS.Core.MessageBodyWriter.pas',
  MARS.Core.MessageBodyWriters in 'dependency\MARS.Core.MessageBodyWriters.pas',
  MARS.Core.Reflection in 'dependency\MARS.Core.Reflection.pas',
  MARS.Core.Registry in 'dependency\MARS.Core.Registry.pas',
  MARS.Core.Response in 'dependency\MARS.Core.Response.pas',
  MARS.Core.Token.InjectionService in 'dependency\MARS.Core.Token.InjectionService.pas',
  MARS.Core.Token in 'dependency\MARS.Core.Token.pas',
  MARS.Core.Token.ReadersAndWriters in 'dependency\MARS.Core.Token.ReadersAndWriters.pas',
  MARS.Core.Token.Resource in 'dependency\MARS.Core.Token.Resource.pas',
  MARS.Core.URL in 'dependency\MARS.Core.URL.pas',
  MARS.Core.Utils in 'dependency\MARS.Core.Utils.pas',
  MARS.Data.FireDAC.DataModule in 'dependency\MARS.Data.FireDAC.DataModule.pas',
  MARS.Data.FireDAC.Editor in 'dependency\MARS.Data.FireDAC.Editor.pas',
  MARS.Data.FireDAC.InjectionService in 'dependency\MARS.Data.FireDAC.InjectionService.pas',
  MARS.Data.FireDAC in 'dependency\MARS.Data.FireDAC.pas',
  MARS.Data.FireDAC.ReadersAndWriters in 'dependency\MARS.Data.FireDAC.ReadersAndWriters.pas',
  MARS.Data.FireDAC.Resources in 'dependency\MARS.Data.FireDAC.Resources.pas',
  MARS.Data.FireDAC.Utils in 'dependency\MARS.Data.FireDAC.Utils.pas',
  MARS.Data.MessageBodyWriters in 'dependency\MARS.Data.MessageBodyWriters.pas',
  MARS.Data.Utils in 'dependency\MARS.Data.Utils.pas',
  MARS.DelphiRazor.InjectionService in 'dependency\MARS.DelphiRazor.InjectionService.pas',
  MARS.DelphiRazor in 'dependency\MARS.DelphiRazor.pas',
  MARS.DelphiRazor.Resources in 'dependency\MARS.DelphiRazor.Resources.pas',
  MARS.dmustache.InjectionService in 'dependency\MARS.dmustache.InjectionService.pas',
  MARS.dmustache in 'dependency\MARS.dmustache.pas',
  MARS.http.Core in 'dependency\MARS.http.Core.pas',
  MARS.http.Server.Indy in 'dependency\MARS.http.Server.Indy.pas',
  MARS.JsonDataObjects.ReadersAndWriters in 'dependency\MARS.JsonDataObjects.ReadersAndWriters.pas',
  MARS.Messaging.Dispatcher in 'dependency\MARS.Messaging.Dispatcher.pas',
  MARS.Messaging.Message in 'dependency\MARS.Messaging.Message.pas',
  MARS.Messaging.Queue in 'dependency\MARS.Messaging.Queue.pas',
  MARS.Messaging.Resource in 'dependency\MARS.Messaging.Resource.pas',
  MARS.Messaging.Subscriber in 'dependency\MARS.Messaging.Subscriber.pas',
  MARS.Metadata.Attributes in 'dependency\MARS.Metadata.Attributes.pas',
  MARS.Metadata.Engine.Resource in 'dependency\MARS.Metadata.Engine.Resource.pas',
  MARS.Metadata.InjectionService in 'dependency\MARS.Metadata.InjectionService.pas',
  MARS.Metadata.JSON in 'dependency\MARS.Metadata.JSON.pas',
  MARS.Metadata in 'dependency\MARS.Metadata.pas',
  MARS.Metadata.Reader in 'dependency\MARS.Metadata.Reader.pas',
  MARS.Metadata.ReadersAndWriters in 'dependency\MARS.Metadata.ReadersAndWriters.pas',
  MARS.Rtti.Utils in 'dependency\MARS.Rtti.Utils.pas',
  MARS.Utils.Parameters.IniFile in 'dependency\MARS.Utils.Parameters.IniFile.pas',
  MARS.Utils.Parameters.JSON in 'dependency\MARS.Utils.Parameters.JSON.pas',
  MARS.Utils.Parameters in 'dependency\MARS.Utils.Parameters.pas',
  MARS.Utils.ReqRespLogger.CodeSite in 'dependency\MARS.Utils.ReqRespLogger.CodeSite.pas',
  MARS.Utils.ReqRespLogger.Interfaces in 'dependency\MARS.Utils.ReqRespLogger.Interfaces.pas',
  MARS.Utils.ReqRespLogger.Memory in 'dependency\MARS.Utils.ReqRespLogger.Memory.pas',
  MARS.WebServer.Resources in 'dependency\MARS.WebServer.Resources.pas',
  MARS.Client.Application in 'dependency\MARS.Client.Application.pas',
  MARS.Client.Client in 'dependency\MARS.Client.Client.pas',
  MARS.Client.CustomResource.Editor in 'dependency\MARS.Client.CustomResource.Editor.pas',
  MARS.Client.CustomResource in 'dependency\MARS.Client.CustomResource.pas',
  MARS.Client.FireDAC in 'dependency\MARS.Client.FireDAC.pas',
  MARS.Client.Messaging.Resource in 'dependency\MARS.Client.Messaging.Resource.pas',
  MARS.Client.Resource.JSON in 'dependency\MARS.Client.Resource.JSON.pas',
  MARS.Client.Resource in 'dependency\MARS.Client.Resource.pas',
  MARS.Client.Resource.Stream in 'dependency\MARS.Client.Resource.Stream.pas',
  MARS.Client.SubResource.JSON in 'dependency\MARS.Client.SubResource.JSON.pas',
  MARS.Client.SubResource in 'dependency\MARS.Client.SubResource.pas',
  MARS.Client.SubResource.Stream in 'dependency\MARS.Client.SubResource.Stream.pas',
  MARS.Client.Token in 'dependency\MARS.Client.Token.pas';

begin
  try
    { TODO -oUser -cConsole Main : Code hier einfügen }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
