unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin, lcltype, Menus, ExtCtrls, SSH_Client, pingsend, blcksock;

type

  { TForm1 }

  TForm1 = class(TForm)
      TLC254: TLabel;
    tb_hostname: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    ListBox1: TListBox;
    Memo1: TMemo;
    SpinEdit1: TSpinEdit;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Memo1KeyPress(Sender: TObject; var Key: char);
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
  sshClient := TSSH_Client.Create(Form1.Memo1);
  sshClient.SetHostName(tb_hostname.Text);
  sshClient.SetUserName(Edit2.Text);
  sshClient.SetPassword(Edit3.Text);
end;

procedure TForm1.Memo1KeyPress(Sender: TObject; var Key: char);
begin
  with Sender as TMemo do
  case Key of
    #13: begin
      sshClient.ssh(Memo1.Lines.ValueFromIndex[Memo1.Lines.Count]);
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
