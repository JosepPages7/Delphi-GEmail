# Delphi-GEmail
Delphi class to send an email using gmail.

 Use sample:

````Delphi

  Gmail := TGmail.Create('YourAccount@gmail.com', 'App password', 'From you/company');
  try
    try
      Gmail.Connect;
      Gmail.Send(['useremail@gmail.com'], 'Subject', 'PlainBody', 'htmlBody', 'AttachmentFile');
      Gmail.Send(...);
      Gmail.Send(...);
    except
      on E: Exception do
        ShowMessage(E.Message);
    end;
  finally
    GEmail.Free;
  end;
  
````

NOTE 1: Add in your executable file path the two openSSL Libraries:  "libeay32.dll"  and  "ssleay32.dll".

NOTE 2: Configure your "YourAccount@gmail.com" Account to allow sending mails from and exertnal app:  Enter in your Personnal Setting (gmail) go to "Security": Activate “2-Step Verification” and add “App Password” or Activate "Allow less secure apps "


More info:
  http://delphiprogrammingdiary.blogspot.com/2016/09/send-email-with-html-body-format-in.html
  http://www.andrecelestino.com/delphi-xe-envio-de-e-mail-com-componentes-indy/

