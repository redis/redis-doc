Switch to a different protocol, optionally authenticating and setting the connection's name, or provide a contextual client report.

Redis version 6 and greater supports two protocols: the old protocol,
RESP2, and a new one introduced with Redis 6, RESP3. RESP3 has certain
advantages since when the connection is in this mode, Redis is able to reply
with more semantical replies: for instance, `HGETALL` will return a *map type*,
so a client library implementation no longer requires to know in advance to
translate the array into a hash before returning it to the caller. For a full
coverage of RESP3, please
[check this repository](https://github.com/antirez/resp3).

In Redis 6 connections start in RESP2 mode, so clients implementing RESP2 do
not need to updated or changed (nor there are short term plans to drop support for
RESP2, but future version may default to RESP3).

When called without any arguments, `HELLO` replies with the current list of
server and connection propeties. In Redis 6.2, and its default use of RESP2
protocol, the reply looks like this:

    > HELLO
     1) "server"
     2) "redis"
     3) "version"
     4) "255.255.255"
     5) "proto"
     6) (integer) 2
     7) "id"
     8) (integer) 5
     9) "mode"
    10) "standalone"
    11) "role"
    12) "master"
    13) "modules"
    14) (empty array)

Clients that want to handshake using the RESP3 mode need to call the `HELLO`
command with the value "3" as first argument, like so:

    > HELLO 3
    1# "server" => "redis"
    2# "version" => "6.0.0"
    3# "proto" => (integer) 3
    4# "id" => (integer) 10
    5# "mode" => "standalone"
    6# "role" => "master"
    7# "modules" => (empty array)

In both cases, `HELLO`'s reply states several useful facts about the server,
such as: versions, modules loaded, client ID, replication role and so forth.
Because of that, and given that the `HELLO` command also works with "2" as an
argument - both to downgrade the protocol back to version 2, or just to get the
reply from the server without switching the protocol - client library authors
may consider using this command instead of the canonical `PING` when setting up
the connection.

When called with the optional `protover` argument, this command switches
the protocol to the specified version. When used in for switching the protocol's
version, the command also accepts the following options:

* `AUTH <username> <password>`: directly authenticate the connection in addition to switching to the specified protocol version. This makes calling `AUTH` before `HELLO` unnecessary when setting up a new connection. Note that the `username` can be set to "default" to authenticate against a server that does not use ACLs, but rather the simpler `requirepass` mechanism of Redis prior to version 6.
* `SETNAME <clientname>`: this is the equivalent of calling `CLIENT SETNAME`.

@return

@array-reply: a list of server properties. The reply is a map instead of an array when RESP3 is selected. The command returns an error if the `protover` requested does not exist.

@history

* `>= 6.2`: `protover` made optional; when called without arguments the command reports the current connection's context.