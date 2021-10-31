// ***************************************************************************
//
// cfs.Email.gmail:
// TcfsGmail is a Delphi class to send an email using gmail
//
// Copyright (c) 2021 Josep Pagès
//
// https://github.com/JosepPages7/Delphi-GEmail
//
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************** }

unit cfs.Email.gmail;

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

