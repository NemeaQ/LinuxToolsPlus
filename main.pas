unit main;

{$mode objfpc}{$H+}
{$IFDEF WIN64}
{$IMAGEBASE $400000}
{$ENDIF}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  lcltype, Menus, ExtCtrls, SSH_Client, pingsend, blcksock;

type

  { TForm1 }

  TForm1 = class(TForm)
      tb_username: TLabeledEdit;
      tb_password: TLabeledEdit;
    la_serverInfo: TLabel;
    TLC254: TLabel;
    lbox_serverInfo: TListBox;
    rtb_log: TMemo;
    tb_port: TLabeledEdit;
    tb_hostname: TLabeledEdit;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure rtb_logKeyPress(Sender: TObject; var Key: char);
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  sshClient: TSSH_Client;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  sshClient := TSSH_Client.Create(rtb_log);
  sshClient.SetHostName(tb_hostname.Text);
  sshClient.SetUserName(tb_username.Text);
  sshClient.SetPassword(tb_password.Text);
  sshClient.SetPort(StrToInt(tb_port.Text));
end;

procedure TForm1.rtb_logKeyPress(Sender: TObject; var Key: char);
begin
  with Sender as TMemo do
  case Key of
    #13: begin
      sshClient.ssh(rtb_log.Lines.ValueFromIndex[rtb_log.Lines.Count]);
      Key := #0;
    end;
    else
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  PingSend: TPINGSend;
begin
  PingSend := TPINGSend.Create;
  try
    PingSend.Timeout := 750;
    if PingSend.Ping('http://thaddy.com') = True then
    begin
      TLC254.Font.Color := $00AA00;
      TLC254.Caption := 'Reply from in: ' + IntToStr(PingSend.PingTime) + ' ms';
    end
    else
    begin
      TLC254.Font.Color := $0000FF;
      TLC254.Caption := 'No response in: ' + IntToStr(PingSend.Timeout) + ' ms ' + PingSend.ReplyErrorDesc;
    end;
   finally
     PingSend.Free;
   end;
end;

end.
