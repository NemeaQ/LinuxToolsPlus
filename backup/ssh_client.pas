unit SSH_Client;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, BaseUnix, StdCtrls, resolve, netdb, libssh2, Sockets;

type

  { SSH Client }

  TSSH_Client = class
  private
    FHostName, FUserName, FPassword: string;
    FPort: longint;
    FMemo: TMemo;
    procedure Log(log_text: string);

  public
    constructor Create(logField: TMemo); overload;
    procedure ssh(cmd: ansistring);
    function GetHostName: string;
    procedure SetHostName(hostName: string);
    function GetPort(): longint;
    procedure SetPort(port: longint);
    function GetUserName: string;
    procedure SetUserName(userName: string);
    function GetPassword: string;
    procedure SetPassword(password: string);

    procedure Connect(_hostname, _username, _password: string; _port: longint);

  published
    property HostName: string read GetHostName write SetHostName;
    property Port: longint read GetPort write SetPort;
    property UserName: string read GetUserName write SetUserName;
    property Password: string read GetPassword write SetPassword;
  end;

implementation

constructor TSSH_Client.Create(logField: TMemo);
begin
  FHostName := '127.0.0.1';
  FPort := 22;
  FUserName := 'root';
  FPassword := 'P@ssw0rd';
  FMemo := logField;
end;

function TSSH_Client.GetHostName(): string;
begin
  Result := FHostName;
end;

procedure TSSH_Client.SetHostName(hostName: string);
begin
  FHostName := hostName;
end;

function TSSH_Client.GetPort(): longint;
begin
  Result := FPort;
end;

procedure TSSH_Client.SetPort(port: longint);
begin
  FPort := port;
end;

function TSSH_Client.GetUserName(): string;
begin
  Result := FUserName;
end;

procedure TSSH_Client.SetUserName(userName: string);
begin
  FUserName := userName;
end;

function TSSH_Client.GetPassword(): string;
begin
  Result := FPassword;
end;

procedure TSSH_Client.SetPassword(password: string);
begin
  FPassword := password;
end;

procedure TSSH_Client.Log(log_text: string);
begin
  FMemo.Lines.Add(log_text);
     {$IFDEF LINUX}
      // scroll down:
      FMemo.SelStart := Length(FMemo.lines.Text) - 1;
      FMemo.VertScrollBar.Position := 1000000;
    {$ELSE }
  SendMessage(FMemo.Handle, WM_VSCROLL, SB_BOTTOM, 0);
    {$ENDIF}
end;

procedure TSSH_Client.Connect(_hostname, _username, _password: string; _port: longint);
begin

end;

procedure TSSH_Client.ssh(cmd: ansistring);
var
  l_session: PLIBSSH2_SESSION;
  l_khost: PLIBSSH2_KNOWNHOST;
  l_khosts: PLIBSSH2_KNOWNHOSTS;
  l_channel: PLIBSSH2_CHANNEL;

  SockAddr: TInetSockAddr;
  HostAddr: THostAddr;
  HostEntry: THostEntry;
  l_socket: cint;

  r: integer;

  l_remote_fingerprint: pansichar;
  l_session_hostkey: pansichar;
  l_userauth_list: pansichar;
  l_buffer: pansichar;

  l_host: ansistring;
  l_user: pansichar;
  l_pass: pansichar;
  l_port: integer;

  o_len: SIZE_T;
  o_type: integer;
  o_out: integer;

  l_buffer2: array [0..4096] of char;

  l_cmd: pansichar;
  i: integer;
begin
  l_session := nil;
  l_channel := nil;

  l_user := PChar(FUserName);
  l_pass := PChar(FPassword);
  l_port := FPort;

  if (ResolveHostByName(FHostName, HostEntry)) then
  begin
    FHostName := NetAddrToStr(HostEntry.Addr);
  end;

  r := libssh2_init(0);

  //**********
  HostAddr := StrToNetAddr(FHostName);
  l_socket := fpsocket(AF_INET, SOCK_STREAM, 0);
  if l_socket = -1 then
    raise Exception.Create('fpsocket');
  SockAddr.sin_family := AF_INET;
  SockAddr.sin_Port := htons(l_port);
  SockAddr.sin_Addr.s_addr := cardinal(HostAddr);

  if fpconnect(l_socket, @SockAddr, SizeOf(SockAddr)) <> 0 then
    raise Exception.Create('fpconnect');
  //**********

  l_session := libssh2_session_init();

  try
    try
      if (Assigned(l_session)) then
      begin
        Log('Session created');
      end
      else
      begin
        Exit;
      end;

      libssh2_session_set_blocking(l_session, 0);

      while True do
      begin
        r := libssh2_session_startup(l_session, l_socket);
        if (r = 0) then
          Break;
        if (r = LIBSSH2_ERROR_EAGAIN) then
          Continue;
      end;
      if (r > 0) then
      begin
        Log('Handshake failure ');
        Exit;
      end;

      l_remote_fingerprint := libssh2_hostkey_hash(l_session, LIBSSH2_HOSTKEY_HASH_SHA1);

      //Печать отпечатка сервера
      Log('Fingerprint: ');
      for i := 0 to 19 do
      begin
        Log(Format('%02X', [Ord(l_remote_fingerprint[i])]));
      end;
      Log('');

      while True do
      begin
        l_userauth_list := libssh2_userauth_list(l_session, pansichar(FUserName), Length(FUserName));
        if (Assigned(l_userauth_list)) then
          Break;

        l_buffer := nil;
        r := libssh2_session_last_error(l_session, l_buffer, o_out, 0);
        if (r = LIBSSH2_ERROR_EAGAIN) then
        begin
          Continue;
        end
        else
        begin
          raise Exception.CreateFmt('Failure: (%d) %s', [r, l_buffer]);
        end;
      end;
      Log(l_userauth_list);


      if Pos('password', l_userauth_list) > 0 then
      begin
        while True do
        begin
          r := libssh2_userauth_password(l_session, pansichar(FUserName), pansichar(FPassword));
          if (r = 0) then
            Break;
          l_buffer := nil;
          r := libssh2_session_last_error(l_session, l_buffer, o_out, 0);
          if (r = LIBSSH2_ERROR_EAGAIN) then
          begin
            Continue;
          end
          else
          begin
            raise Exception.CreateFmt('Failure: (%d) %s', [r, l_buffer]);
          end;
        end;
      end
      else if Pos('publickey', l_userauth_list) > 0 then
      begin

      end;

      //is authenticated?
      r := libssh2_userauth_authenticated(l_session);
      if (r = 0) then
      begin
        raise Exception.CreateFmt('Failure: (%d) is not authenticated', [r]);
      end;

      while True do
      begin
        l_channel := libssh2_channel_open_ex(l_session, 'session', Length('session'), LIBSSH2_CHANNEL_WINDOW_DEFAULT, LIBSSH2_CHANNEL_PACKET_DEFAULT, nil, 0);
        if (Assigned(l_channel)) then
          Break;
        //waitSock(l_socket, l_session);
        l_buffer := nil;
        r := libssh2_session_last_error(l_session, l_buffer, o_out, 0);
        if (r = LIBSSH2_ERROR_EAGAIN) then
        begin
          Continue;
        end
        else
        begin
          raise Exception.CreateFmt('Failure: (%d) %s', [r, l_buffer]);
        end;
      end;
      if (Assigned(l_channel)) then
      begin
        Log('Channel opened');
        while True do
        begin
          l_cmd := PChar(cmd);
          r := libssh2_channel_process_startup(l_channel, 'exec', Length('exec'), l_cmd, Length(l_cmd));
          if (r = 0) then
            Break;
          l_buffer := nil;
          r := libssh2_session_last_error(l_session, l_buffer, o_out, 0);
          if (r = LIBSSH2_ERROR_EAGAIN) then
          begin
            Continue;
          end
          else
          begin
            raise Exception.CreateFmt('Failure: (%d) %s', [r, l_buffer]);
          end;
        end;
        if (True) then
        begin
          Log('Command executed');
          while (True) do
          begin
            for i := 0 to High(l_buffer2) do
            begin
              l_buffer2[i] := #0;
            end;
            r := libssh2_channel_read_ex(l_channel, 0, @l_buffer2, High(l_buffer2));
            if (r > 0) then
            begin
              Log(l_buffer2);
              Continue;
            end;

            if (r = 0) then
              Break;

            l_buffer := nil;
            r := libssh2_session_last_error(l_session, l_buffer, o_out, 0);
            if (r = LIBSSH2_ERROR_EAGAIN) then
            begin
              Continue;
            end
            else
            begin
              raise Exception.CreateFmt('Failure: (%d) %s', [r, l_buffer]);
            end;
          end;
        end;
      end;
    except
      on E: Exception do
      begin
        Log(E.Message);
      end;
    end;
  finally
    if (Assigned(l_channel)) then
    begin
      libssh2_channel_close(l_channel);
      libssh2_channel_free(l_channel);
    end;
    if (Assigned(l_session)) then
    begin
      libssh2_session_disconnect(l_session, 'Tchau');
      libssh2_session_free(l_session);
    end;
    if (l_socket > 0) then
    begin
      FpClose(l_socket);
    end;
    libssh2_exit();
  end;

end;

end.
