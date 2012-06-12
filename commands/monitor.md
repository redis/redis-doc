`MONITOR` is a debugging command that streams back every command
processed by the Redis server. It can help in understanding what is
happening to the database. This command can both be used via `redis-cli`
and via `telnet`.

The ability to see all the requests processed by the server is useful in
order to spot bugs in an application both when using Redis as a database
and as a distributed caching system.

```
$ redis-cli monitor
1339518083.107412 [0 127.0.0.1:60866] "keys" "*"
1339518087.877697 [0 127.0.0.1:60866] "dbsize"
1339518090.420270 [0 127.0.0.1:60866] "set" "x" "6"
1339518096.506257 [0 127.0.0.1:60866] "get" "x"
1339518099.363765 [0 127.0.0.1:60866] "del" "x"
1339518100.544926 [0 127.0.0.1:60866] "get" "x"
```

Use `SIGINT` (Ctrl-C) to stop a `MONITOR` stream running via
`redis-cli`.

```
$ telnet localhost 6379
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
MONITOR
+OK
+1339518083.107412 [0 127.0.0.1:60866] "keys" "*"
+1339518087.877697 [0 127.0.0.1:60866] "dbsize"
+1339518090.420270 [0 127.0.0.1:60866] "set" "x" "6"
+1339518096.506257 [0 127.0.0.1:60866] "get" "x"
+1339518099.363765 [0 127.0.0.1:60866] "del" "x"
+1339518100.544926 [0 127.0.0.1:60866] "get" "x"
QUIT
+OK
Connection closed by foreign host.
```

Manually issue the `QUIT` command to stop a `MONITOR` stream running via
`telnet`.

@return

**Non standard return value**, just dumps the received commands in an infinite
flow.
