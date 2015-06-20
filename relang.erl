-module(relang).

-author(kureikain).
-email("kurei@axcoto.com").

%%-export([connect/1]).
-compile(export_all). %% replace with -export() later, for God's sake!

%% From ql2.proto
-define(RETHINKDB_VERSION, 32#723081e1).

%% http://erlang.org/pipermail/erlang-questions/2004-December/013734.html
connect(RethinkDBHost) ->
  {ok, Sock} = gen_tcp:connect(RethinkDBHost, 28015,
                               [binary, {packet, 0}, {active, false}]),
  Sock.

close(Sock) ->
  gen_tcp:close(Sock).

handshake(Sock, AuthKey) ->
  KeyLength = iolist_size(AuthKey),
  ok = gen_tcp:send(Sock, binary:encode_unsigned(16#400c2d20, little)),
  %%ok = gen_tcp:send(Sock, [<<KeyLength:32/little-unsigned>>, AuthKey]),
  ok = gen_tcp:send(Sock, [<<0:32/little-unsigned>>]),
  %%ok = gen_tcp:send(Sock, binary:encode_unsigned(16#0)),
  %%ok = gen_tcp:send(Sock, binary:encode_unsigned(16#0)),
  %%ok = gen_tcp:send(Sock, binary:encode_unsigned(16#7e6970c7)),
  ok = gen_tcp:send(Sock, [<<16#7e6970c7:32/little-unsigned>>]),
  {ok, Response} = read_until_null(Sock),
  case Response == <<"SUCCESS",0>> of
      true -> ok;
      false ->
          io:fwrite("Error: ~s~n", [Response]),
          {error, Response}
  end.

run() ->
  RethinkDBHost = "127.0.0.1", % to make it runnable on one machine
  RethinkSock   = connect(RethinkDBHost),
  handshake(RethinkSock, <<"">>),
  close(RethinkSock).

read_until_null(Socket) ->
    read_until_null(Socket, []).

read_until_null(Socket, Acc) ->
    %%{ok, Response} = gen_tcp:recv(Socket, 0),
    case gen_tcp:recv(Socket, 0) of
      {error, OtherSendError} ->
        io:format("Some other error on socket (~p), closing", [OtherSendError]),
        %%Client ! {self(),{error_sending, OtherSendError}},
        gen_tcp:close(Socket);
      {ok, Response} ->
        Result = [Acc, Response],
        case is_null_terminated(Response) of
            true -> {ok, iolist_to_binary(Result)};
            false -> read_until_null(Socket, Result)
        end
    end.

is_null_terminated(B) ->
    binary:at(B, iolist_size(B) - 1) == 0.
