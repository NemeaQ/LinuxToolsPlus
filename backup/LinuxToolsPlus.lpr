program LinuxToolsPlus;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces,
  Forms, main, SSH_Client;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Title:='Linux Tools Plus';
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
  Application.Free;
end.

