`MONITOR` is a debugging command that streams back every command processed by
the Redis server.
It can help in understanding what is happening to the database.
This command can both be used via `redis-cli` and via `telnet`.

The ability to see all the requests processed by the server is useful in order
to spot bugs in an application both when using Redis as a database and as a
distributed caching system.

```
$ redis-cli monitor
1339518083.107412 [0 127.0.0.1:60866] "keys" "*"
1339518087.877697 [0 127.0.0.1:60866] "dbsize"
1339518090.420270 [0 127.0.0.1:60866] "set" "x" "6"
1339518096.506257 [0 127.0.0.1:60866] "get" "x"
1339518099.363765 [0 127.0.0.1:60866] "eval" "return redis.call('set','x','7')" "0"
1339518100.363799 [0 lua] "set" "x" "7"
1339518100.544926 [0 127.0.0.1:60866] "del" "x"
```

Use `SIGINT` (Ctrl-C) to stop a `MONITOR` stream running via `redis-cli`.

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

Manually issue the `QUIT` or `RESET` commands to stop a `MONITOR` stream running
via `telnet`.

## Commands not logged by MONITOR

Because of security concerns, no administrative commands are logged
by `MONITOR`'s output and sensitive data is redacted in the command `AUTH`.

Furthermore, the command `QUIT` is also not logged.

## Cost of running MONITOR

Because `MONITOR` streams back **all** commands, its use comes at a cost.
The following (totally unscientific) benchmark numbers illustrate what the cost
of running `MONITOR` can be.

Benchmark result **without** `MONITOR` running:

```
$ src/redis-benchmark -c 10 -n 100000 -q
PING_INLINE: 101936.80 requests per second
PING_BULK: 102880.66 requests per second
SET: 95419.85 requests per second
GET: 104275.29 requests per second
INCR: 93283.58 requests per second
```

Benchmark result **with** `MONITOR` running (`redis-cli monitor > /dev/null`):

```
$ src/redis-benchmark -c 10 -n 100000 -q
PING_INLINE: 58479.53 requests per second
PING_BULK: 59136.61 requests per second
SET: 41823.50 requests per second
GET: 45330.91 requests per second
INCR: 41771.09 requests per second
```

In this particular case, running a single `MONITOR` client can reduce the
throughput by more than 50%.
Running more `MONITOR` clients will reduce throughput even more.

@return

**Non standard return value**, just dumps the received commands in an infinite
flow.

## Behavior change history

*   `>= 6.0.0`: `AUTH` excluded from the command's output.
*   `>= 6.2.0`: "`RESET` can be called to exit monitor mode.
*   `>= 6.2.4`: "`AUTH`, `HELLO`, `EVAL`, `EVAL_RO`, `EVALSHA` and `EVALSHA_RO` included in the command's output.