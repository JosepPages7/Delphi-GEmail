unit cfs.Email.gmail;

(*
  http://forums.unigui.com/index.php?/topic/13807-sending-email/
   Step by Step :
  1. if you have not a gmail account, Create it.
  2. Important :
   -  Enter in your Personnal Setting (gmail) go to "Security":
      Activate “2-Step Verification” and add “App Password”
      or Activate "Allow less secure apps "
  3.  Add in your executable file path the two openSSL Libraries:  "libeay32.dll"  and  "ssleay32.dll"

  More info:
  http://delphiprogrammingdiary.blogspot.com/2016/09/send-email-with-html-body-format-in.html
  http://www.andrecelestino.com/delphi-xe-envio-de-e-mail-com-componentes-indy/

*)

(*
  Use sample:

  Gmail := TcfsGmail.Create('YourAccount@gmail.com', 'App password', 'From you/company');
  try
    try
      Gmail.Connect;
      Gmail.Send(['useremail@gmail.com'], 'Subject', 'PlainBody', 'htmlBody', 'AttachmentFile');
      //Gmail.Send(...);
      //Gmail.Send(...);
    except
      on E: Exception do
        ShowMessage(E.Message);
    end;
  finally
    GEmail.Free;
  end;
*)

interface

uses
  System.SysUtils, System.Classes, IdTCPConnection, IdExplicitTLSClientServerBase, IdMessageClient,  IdSMTP, IdMessage, IdIOHandler,
  IdBaseComponent, IdComponent, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdText, IdAttachmentFile;

type
  TcfsGmail = class
  private
    FFromName: string;
    FIdSSLIOHandlerSocket: TIdSSLIOHandlerSocketOpenSSL;
    FIdSMTP: TIdSMTP;
  public
    constructor Create(const UserName, Password, FromName: string);
    destructor Destroy; override;
    procedure Connect;
    procedure Send(ToAddresses: array of string; const Subject, PlainBody: string; const HTMLBody: string = ''; const AttachmentFile: string = '');
 end;

implementation


constructor TcfsGmail.Create(const UserName, Password, FromName: string);
begin
  FFromName := FromName;

  FIdSSLIOHandlerSocket := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  FIdSSLIOHandlerSocket.SSLOptions.Method := sslvSSLv23;
  FIdSSLIOHandlerSocket.SSLOptions.Mode := sslmClient;
  FIdSSLIOHandlerSocket.SSLOptions.SSLVersions := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];

  FIdSMTP := TIdSMTP.Create(nil);
  FIdSMTP.IOHandler := FIdSSLIOHandlerSocket;
  FIdSMTP.UseTLS := utUseImplicitTLS;
  FIdSMTP.AuthType := satDefault;

  FIdSMTP.Host := 'smtp.gmail.com';
  FIdSMTP.Port := 465;

  FIdSMTP.Username := UserName;
  FIdSMTP.Password := Password;
end;

destructor TcfsGmail.Destroy;
begin
  if Assigned(FIdSMTP) then
  begin
    try
      FIdSMTP.Disconnect;
    except
    end;
    UnLoadOpenSSLLibrary;
    FreeAndNil(FIdSMTP);
  end;
  if Assigned(FIdSSLIOHandlerSocket) then
    FreeAndNil(FIdSSLIOHandlerSocket);

  inherited;
end;

procedure TcfsGmail.Connect;
begin
  FIdSMTP.Connect;
  FIdSMTP.Authenticate;
end;

procedure TcfsGmail.Send(ToAddresses: array of string; const Subject, PlainBody: string; const HTMLBody: string = ''; const AttachmentFile: string = '');
var
  IdMessage: TIdMessage;
  IdText: TIdText;
  Address: string;
  AttachFileExist: Boolean;
  MultipartAlternative: Boolean;
begin
  if not FIdSMTP.Connected then
    Connect;

  IdMessage := TIdMessage.Create(nil);
  try
    IdMessage.From.Address := FIdSMTP.Username;
    IdMessage.From.Name := FFromName;

    for Address in ToAddresses do
    begin
      if Address <> '' then
        IdMessage.Recipients.Add.Text := Address;
    end;

    IdMessage.Subject := Subject;

    AttachFileExist := False;
    if AttachmentFile <> '' then
      AttachFileExist := FileExists(AttachmentFile);

    MultipartAlternative := False;
    if (PlainBody <> '') and (HTMLBody <> '')  then
      MultipartAlternative := True;

    IdMessage.ContentType := 'multipart/alternative';
    if AttachFileExist then
    begin
      if MultipartAlternative then
        IdMessage.ContentType := 'multipart/related; type="multipart/alternative"'
      else
        IdMessage.ContentType := 'multipart/mixed';
    end;

    if MultipartAlternative and AttachFileExist then
    begin
      IdText := TIdText.Create(IdMessage.MessageParts);
      IdText.ContentType := 'multipart/alternative';
    end;

    // plain body
    if PlainBody <> '' then
    begin
      IdText := TIdText.Create(IdMessage.MessageParts);
      IdText.ContentType := 'text/plain; charset="UTF-8"';
      IdText.Body.Text := PlainBody;
      if MultipartAlternative and AttachFileExist then
        IdText.ParentPart := 0;
    end;

    // html body
    if HTMLBody <> '' then
    begin
      IdText := TIdText.Create(IdMessage.MessageParts);
      IdText.ContentType := 'text/html; charset="UTF-8"';
      IdText.Body.Text := HTMLBody;
      if MultipartAlternative and AttachFileExist then
        IdText.ParentPart := 0;
    end;

    if AttachFileExist then
      TIdAttachmentFile.Create(IdMessage.MessageParts, AttachmentFile);

    FIdSMTP.Send(IdMessage);
  finally
    IdMessage.Free;
  end;
end;

end.

