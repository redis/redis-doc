---
title: "Redis CLI"
linkTitle: "CLI"
weight: 1
description: >
    Overview of redis-cli, the Redis command line interface
aliases:
    - /docs/manual/cli
---

The Redis command line interface (`redis-cli`) is a terminal program used to send commands to and read replies from the Redis server. It has two main modes: an interactive Read Eval Print Loop (REPL) mode where the user types Redis commands and receives replies, and a command mode where `redis-cli` is executed with additional arguments and the reply is printed to the standard output.

In interactive mode, `redis-cli` has basic line editing capabilities to provide a familiar tyPING experience.

To launch the program in special modes, you can use several options, including:

* Simulate a replica and print the replication stream it receives from the primary.
* Check the latency of a Redis server and display statistics. 
* Request ASCII-art spectrogram of latency samples and frequencies.

This topic covers the different aspects of `redis-cli`, starting from the simplest and ending with the more advanced features.

## Command line usage

To run a Redis command and return a standard output at the terminal, include the command to execute as separate arguments of `redis-cli`:

    $ redis-cli INCR mycounter
    (integer) 7

The reply of the command is "7". Since Redis replies are typed (strings, arrays, integers, nil, errors, etc.), you see the type of the reply between parentheses. This additional information may not be ideal when the output of `redis-cli` must be used as input of another command or redirected into a file.

`redis-cli` only shows additional information for human readibility when it detects the standard output is a tty, or terminal. For all other outputs it will auto-enable the *raw output mode*, as in the following example:

    $ redis-cli INCR mycounter > /tmp/output.txt
    $ cat /tmp/output.txt
    8

Note that `(integer)` is omitted from the output because `redis-cli` detects
the output is no longer written to the terminal. You can force raw output
even on the terminal with the `--raw` option:

    $ redis-cli --raw INCR mycounter
    9

You can force human readable output when writing to a file or in
pipe to other commands by using `--no-raw`.

## String escaping

When using escape sequences, ensure that you enclose them in double (`"`) or single (`'`) quotation marks. Escape sequences are used to put nonprintable characters in character and string literals. Examples of using escape sequences to display characters include tab, carriage return, backspace, and many more.

An escape sequence contains a backslash (`\`) symbol followed by one of the escape sequence characters.

Escape sequences can include:

* `\n` - newline
* `\r` - carriage return
* `\t` - horizontal tab
* `\b` - backspace
* `\a` - alert
* `\\` - backslash
* `\xhh` - any ASCII character represented by a hexadecimal number (_hh_)

Double quotes allow you to incorporate escape sequences using `\`. Single quotes assume the string is literal.

For example, to return `Hello World` on two lines:

```
127.0.0.1:6379> SET mykey "Hello\nWorld"
OK
127.0.0.1:6379> GET mykey
Hello
World
```

When you input strings that contain single or double quotes, as you might in passwords, for example, escape the string, like so: 

```
 AUTH some_admin_user ">^8T>6Na{u|jp>+v\"55\@_;OU(OR]7mbAYGqsfyu48(j'%hQH7;v*f1H${*gD(Se'"
 ```

## Host, port, password, and database

By default, `redis-cli` connects to the server at the address 127.0.0.1 with port 6379.
You can change the port using several command line options. To specify a different host name or an IP address, use the `-h` option. In order to set a different port, use `-p`.

    $ redis-cli -h redis15.localnet.org -p 6390 PING
    PONG

If your instance is password protected, the `-a <password>` option will
preform authentication saving the need of explicitly using the `AUTH` command:

    $ redis-cli -a myUnguessablePazzzzzword123 PING
    PONG

**NOTE:** For security reasons, provide the password to `redis-cli` automatically via the
`REDISCLI_AUTH` environment variable.

Finally, it's possible to send a command that operates on a database number
other than the default number zero by using the `-n <dbnum>` option:

    $ redis-cli FLUSHALL
    OK
    $ redis-cli -n 1 INCR a
    (integer) 1
    $ redis-cli -n 1 INCR a
    (integer) 2
    $ redis-cli -n 2 INCR a
    (integer) 1

Some or all of this information can also be provided by using the `-u <uri>`
option and the URI pattern `redis://user:password@host:port/dbnum`:

    $ redis-cli -u redis://LJenkins:p%40ssw0rd@redis-16379.hosted.com:16379/0 PING
    PONG

## SSL/TLS

By default, `redis-cli` uses a plain TCP connection to connect to Redis.
You may enable SSL/TLS using the `--tls` option, along with `--cacert` or
`--cacertdir` to configure a trusted root certificate bundle or directory.

If the target server requires authentication using a client side certificate,
you can specify a certificate and a corresponding private key using `--cert` and
`--key`.

## Getting input from other programs

There are two ways you can use `redis-cli` in order to receive input from other
commands via the standard input. One is to use the target payload as the last argument
from *stdin*. For example, in order to set the Redis key `net_services`
to the content of the file `/etc/services` from a local file system, use the `-x`
option:

    $ redis-cli -x SET net_services < /etc/services
    OK
    $ redis-cli GETRANGE net_services 0 50
    "#\n# Network services, Internet style\n#\n# Note that "

In the first line of the above session, `redis-cli` was executed with the `-x` option and a file was redirected to the CLI's
standard input as the value to satisfy the `SET net_services` command phrase. This is useful for scripting.

A different approach is to feed `redis-cli` a sequence of commands written in a
text file:

    $ cat /tmp/commands.txt
    SET item:3374 100
    INCR item:3374
    APPEND item:3374 xxx
    GET item:3374
    $ cat /tmp/commands.txt | redis-cli
    OK
    (integer) 101
    (integer) 6
    "101xxx"

All the commands in `commands.txt` are executed consecutively by
`redis-cli` as if they were typed by the user in interactive mode. Strings can be
quoted inside the file if needed, so that it's possible to have single
arguments with spaces, newlines, or other special characters:

    $ cat /tmp/commands.txt
    SET arg_example "This is a single argument"
    STRLEN arg_example
    $ cat /tmp/commands.txt | redis-cli
    OK
    (integer) 25

## Continuously run the same command

It is possible to execute a single command a specified number of times
with a user-selected pause between executions. This is useful in
different contexts - for example when we want to continuously monitor some
key content or `INFO` field output, or when we want to simulate some
recurring write event, such as pushing a new item into a list every 5 seconds.

This feature is controlled by two options: `-r <count>` and `-i <delay>`.
The `-r` option states how many times to run a command and `-i` sets
the delay between the different command calls in seconds (with the ability
to specify values such as 0.1 to represent 100 milliseconds).

By default the interval (or delay) is set to 0, so commands are just executed
ASAP:

    $ redis-cli -r 5 INCR counter_value
    (integer) 1
    (integer) 2
    (integer) 3
    (integer) 4
    (integer) 5

To run the same command indefinitely, use `-1` as the count value.
To monitor over time the RSS memory size it's possible to use the following command:

    $ redis-cli -r -1 -i 1 INFO | grep rss_human
    used_memory_rss_human:2.71M
    used_memory_rss_human:2.73M
    used_memory_rss_human:2.73M
    used_memory_rss_human:2.73M
    ... a new line will be printed each second ...

## Mass insertion of data using `redis-cli`

Mass insertion using `redis-cli` is covered in a separate page as it is a
worthwhile topic itself. Please refer to our [mass insertion guide](/topics/mass-insert).

## CSV output

A CSV (Comma Separated Values) output feature exists within `redis-cli` to export data from Redis to an external program.  

    $ redis-cli LPUSH mylist a b c d
    (integer) 4
    $ redis-cli --csv LRANGE mylist 0 -1
    "d","c","b","a"

Note that the `--csv` flag will only work on a single command, not the entirety of a DB as an export.

## Running Lua scripts

The `redis-cli` has extensive support for using the debugging facility
of Lua scripting, available with Redis 3.2 onwards. For this feature, refer to the [Redis Lua debugger documentation](/topics/ldb).

Even without using the debugger, `redis-cli` can be used to
run scripts from a file as an argument:

    $ cat /tmp/script.lua
    return redis.call('SET',KEYS[1],ARGV[1])
    $ redis-cli --eval /tmp/script.lua location:hastings:temp , 23
    OK

The Redis `EVAL` command takes the list of keys the script uses, and the
other non key arguments, as different arrays. When calling `EVAL` you
provide the number of keys as a number. 

When calling `redis-cli` with the `--eval` option above, there is no need to specify the number of keys
explicitly. Instead it uses the convention of separating keys and arguments
with a comma. This is why in the above call you see `location:hastings:temp , 23` as arguments.

So `location:hastings:temp` will populate the `KEYS` array, and `23` the `ARGV` array.

The `--eval` option is useful when writing simple scripts. For more
complex work, the Lua debugger is recommended. It is possible to mix the two approaches, since the debugger can also execute scripts from an external file.

Interactive mode
===

We have explored how to use the Redis CLI as a command line program.
This is useful for scripts and certain types of testing, however most
people will spend the majority of time in `redis-cli` using its interactive
mode.

In interactive mode the user types Redis commands at the prompt. The command
is sent to the server, processed, and the reply is parsed back and rendered
into a simpler form to read.

Nothing special is needed for running the `redis-cli`in interactive mode -
just execute it without any arguments

    $ redis-cli
    127.0.0.1:6379> PING
    PONG

The string `127.0.0.1:6379>` is the prompt. It displays the connected Redis server instance's hostname and port.

The prompt updates as the connected server changes or when operating on a database different from the database number zero:

    127.0.0.1:6379> SELECT 2
    OK
    127.0.0.1:6379[2]> DBSIZE
    (integer) 1
    127.0.0.1:6379[2]> SELECT 0
    OK
    127.0.0.1:6379> DBSIZE
    (integer) 503

## Handling connections and reconnections

Using the `CONNECT` command in interactive mode makes it possible to connect
to a different instance, by specifying the *hostname* and *port* we want
to connect to:

    127.0.0.1:6379> CONNECT metal 6379
    metal:6379> PING
    PONG

As you can see the prompt changes accordingly when connecting to a different server instance.
If a connection is attempted to an instance that is unreachable, the `redis-cli` goes into disconnected
mode and attempts to reconnect with each new command:

    127.0.0.1:6379> CONNECT 127.0.0.1 9999
    Could not connect to Redis at 127.0.0.1:9999: Connection refused
    not connected> PING
    Could not connect to Redis at 127.0.0.1:9999: Connection refused
    not connected> PING
    Could not connect to Redis at 127.0.0.1:9999: Connection refused

Generally after a disconnection is detected, `redis-cli` always attempts to
reconnect transparently; if the attempt fails, it shows the error and
enters the disconnected state. The following is an example of disconnection
and reconnection:

    127.0.0.1:6379> INFO SERVER
    Could not connect to Redis at 127.0.0.1:6379: Connection refused
    not connected> PING
    PONG
    127.0.0.1:6379> 
    (now we are connected again)

When a reconnection is performed, `redis-cli` automatically re-selects the
last database number selected. However, all other states about the
connection is lost, such as within a MULTI/EXEC transaction:

    $ redis-cli
    127.0.0.1:6379> MULTI
    OK
    127.0.0.1:6379> PING
    QUEUED

    ( here the server is manually restarted )

    127.0.0.1:6379> EXEC
    (error) ERR EXEC without MULTI

This is usually not an issue when using the `redis-cli` in interactive mode for
testing, but this limitation should be known.

## Editing, history, completion and hints

Because `redis-cli` uses the
[linenoise line editing library](http://github.com/antirez/linenoise), it
always has line editing capabilities, without depending on `libreadline` or
other optional libraries.

Command execution history can be accessed in order to avoid retyping commands by pressing the arrow keys (up and down).
The history is preserved between restarts of the CLI, in a file named
`.rediscli_history` inside the user home directory, as specified
by the `HOME` environment variable. It is possible to use a different
history filename by setting the `REDISCLI_HISTFILE` environment variable,
and disable it by setting it to `/dev/null`.

The `redis-cli` is also able to perform command-name completion by pressing the TAB
key, as in the following example:

    127.0.0.1:6379> Z<TAB>
    127.0.0.1:6379> ZADD<TAB>
    127.0.0.1:6379> ZCARD<TAB>

Once Redis command name has been entered at the prompt, the `redis-cli` will display
syntax hints. Like command history, this behavior can be turned on and off via the `redis-cli` preferences.

## Preferences

There are two ways to customize `redis-cli` behavior. The file `.redisclirc`
in the home directory is loaded by the CLI on startup. You can override the
file's default location by setting the `REDISCLI_RCFILE` environment variable to
an alternative path. Preferences can also be set during a CLI session, in which 
case they will last only the duration of the session.

To set preferences, use the special `:set` command. The following preferences
can be set, either by typing the command in the CLI or adding it to the
`.redisclirc` file:

* `:set hints` - enables syntax hints
* `:set nohints` - disables syntax hints

## Running the same command N times

It is possible to run the same command multiple times in interactive mode by prefixing the command
name by a number:

    127.0.0.1:6379> 5 INCR mycounter
    (integer) 1
    (integer) 2
    (integer) 3
    (integer) 4
    (integer) 5

## Showing help about Redis commands

`redis-cli` provides online help for most Redis [commands](/commands), using the `HELP` command. The command can be used
in two forms:

* `HELP @<category>` shows all the commands about a given category. The
categories are: 
    - `@generic`
    - `@string`
    - `@list`
    - `@set`
    - `@sorted_set`
    - `@hash`
    - `@pubsub`
    - `@transactions`
    - `@connection`
    - `@server`
    - `@scripting`
    - `@hyperloglog`
    - `@cluster`
    - `@geo`
    - `@stream`
* `HELP <commandname>` shows specific help for the command given as argument.

For example in order to show help for the `PFADD` command, use:

    127.0.0.1:6379> HELP PFADD

    PFADD key element [element ...]
    summary: Adds the specified elements to the specified HyperLogLog.
    since: 2.8.9

Note that `HELP` supports TAB completion as well.

## Clearing the terminal screen

Using the `CLEAR` command in interactive mode clears the terminal's screen.

Special modes of operation
===

So far we saw two main modes of `redis-cli`.

* Command line execution of Redis commands.
* Interactive "REPL" usage.

The CLI performs other auxiliary tasks related to Redis that
are explained in the next sections:

* Monitoring tool to show continuous stats about a Redis server.
* Scanning a Redis database for very large keys.
* Key space scanner with pattern matching.
* Acting as a [Pub/Sub](/topics/pubsub) client to subscribe to channels.
* Monitoring the commands executed into a Redis instance.
* Checking the [latency](/topics/latency) of a Redis server in different ways.
* Checking the scheduler latency of the local computer.
* Transferring RDB backups from a remote Redis server locally.
* Acting as a Redis replica for showing what a replica receives.
* Simulating [LRU](/topics/lru-cache) workloads for showing stats about keys hits.
* A client for the Lua debugger.

## Continuous stats mode

Continuous stats mode is probably one of the lesser known yet very useful features of `redis-cli` to monitor Redis instances in real time. To enable this mode, the `--stat` option is used.
The output is very clear about the behavior of the CLI in this mode:

    $ redis-cli --stat
    ------- data ------ --------------------- load -------------------- - child -
    keys       mem      clients blocked requests            connections
    506        1015.00K 1       0       24 (+0)             7
    506        1015.00K 1       0       25 (+1)             7
    506        3.40M    51      0       60461 (+60436)      57
    506        3.40M    51      0       146425 (+85964)     107
    507        3.40M    51      0       233844 (+87419)     157
    507        3.40M    51      0       321715 (+87871)     207
    508        3.40M    51      0       408642 (+86927)     257
    508        3.40M    51      0       497038 (+88396)     257

In this mode a new line is printed every second with useful information and differences of request values between old data points. Memory usage, client connection counts, and various other statistics about the connected Redis database can be easily understood with this auxiliary `redis-cli` tool.

The `-i <interval>` option in this case works as a modifier in order to
change the frequency at which new lines are emitted. The default is one
second.

## Scanning for big keys

In this special mode, `redis-cli` works as a key space analyzer. It scans the
dataset for big keys, but also provides information about the data types
that the data set consists of. This mode is enabled with the `--bigkeys` option,
and produces verbose output:

    $ redis-cli --bigkeys

    # Scanning the entire keyspace to find biggest keys as well as
    # average sizes per key type.  You can use -i 0.01 to sleep 0.01 sec
    # per SCAN command (not usually needed).

    [00.00%] Biggest string found so far 'key-419' with 3 bytes
    [05.14%] Biggest list   found so far 'mylist' with 100004 items
    [35.77%] Biggest string found so far 'counter:__rand_int__' with 6 bytes
    [73.91%] Biggest hash   found so far 'myobject' with 3 fields

    -------- summary -------

    Sampled 506 keys in the keyspace!
    Total key length in bytes is 3452 (avg len 6.82)

    Biggest string found 'counter:__rand_int__' has 6 bytes
    Biggest   list found 'mylist' has 100004 items
    Biggest   hash found 'myobject' has 3 fields

    504 strings with 1403 bytes (99.60% of keys, avg size 2.78)
    1 lists with 100004 items (00.20% of keys, avg size 100004.00)
    0 sets with 0 members (00.00% of keys, avg size 0.00)
    1 hashs with 3 fields (00.20% of keys, avg size 3.00)
    0 zsets with 0 members (00.00% of keys, avg size 0.00)

In the first part of the output, each new key larger than the previous larger
key (of the same type) encountered is reported. The summary section
provides general stats about the data inside the Redis instance.

The program uses the `SCAN` command, so it can be executed against a busy
server without impacting the operations, however the `-i` option can be
used in order to throttle the scanning process of the specified fraction
of second for each `SCAN` command. 

For example, `-i 0.01` will slow down the program execution considerably, but will also reduce the load on the server
to a negligible amount.

Note that the summary also reports in a cleaner form the biggest keys found
for each time. The initial output is just to provide some interesting info
ASAP if running against a very large data set.

## Getting a list of keys

It is also possible to scan the key space, again in a way that does not
block the Redis server (which does happen when you use a command
like `KEYS *`), and print all the key names, or filter them for specific
patterns. This mode, like the `--bigkeys` option, uses the `SCAN` command,
so keys may be reported multiple times if the dataset is changing, but no
key would ever be missing, if that key was present since the start of the
iteration. Because of the command that it uses this option is called `--scan`.

    $ redis-cli --scan | head -10
    key-419
    key-71
    key-236
    key-50
    key-38
    key-458
    key-453
    key-499
    key-446
    key-371

Note that `head -10` is used in order to print only the first lines of the
output.

Scanning is able to use the underlying pattern matching capability of
the `SCAN` command with the `--pattern` option.

    $ redis-cli --scan --pattern '*-11*'
    key-114
    key-117
    key-118
    key-113
    key-115
    key-112
    key-119
    key-11
    key-111
    key-110
    key-116

Piping the output through the `wc` command can be used to count specific
kind of objects, by key name:

    $ redis-cli --scan --pattern 'user:*' | wc -l
    3829433

You can use `-i 0.01` to add a delay between calls to the `SCAN` command.
This will make the command slower but will significantly reduce load on the server.

## Pub/sub mode

The CLI is able to publish messages in Redis Pub/Sub channels using
the `PUBLISH` command. Subscribing to channels in order to receive
messages is different - the terminal is blocked and waits for
messages, so this is implemented as a special mode in `redis-cli`. Unlike
other special modes this mode is not enabled by using a special option,
but simply by using the `SUBSCRIBE` or `PSUBSCRIBE` command, which are available in
interactive or command mode:

    $ redis-cli PSUBSCRIBE '*'
    Reading messages... (press Ctrl-C to quit)
    1) "PSUBSCRIBE"
    2) "*"
    3) (integer) 1

The *reading messages* message shows that we entered Pub/Sub mode.
When another client publishes some message in some channel, such as with the command `redis-cli PUBLISH mychannel mymessage`, the CLI in Pub/Sub mode will show something such as:

    1) "pmessage"
    2) "*"
    3) "mychannel"
    4) "mymessage"

This is very useful for debugging Pub/Sub issues.
To exit the Pub/Sub mode just process `CTRL-C`.

## Monitoring commands executed in Redis

Similarly to the Pub/Sub mode, the monitoring mode is entered automatically
once you use the `MONITOR` command. All commands received by the active Redis instance will be printed to the standard output:

    $ redis-cli MONITOR
    OK
    1460100081.165665 [0 127.0.0.1:51706] "set" "shipment:8000736522714:status" "sorting"
    1460100083.053365 [0 127.0.0.1:51707] "get" "shipment:8000736522714:status"

Note that it is possible to use to pipe the output, so you can monitor
for specific patterns using tools such as `grep`.

## Monitoring the latency of Redis instances

Redis is often used in contexts where latency is very critical. Latency
involves multiple moving parts within the application, from the client library
to the network stack, to the Redis instance itself.

The `redis-cli` has multiple facilities for studying the latency of a Redis
instance and understanding the latency's maximum, average and distribution.

The basic latency-checking tool is the `--latency` option. Using this
option the CLI runs a loop where the `PING` command is sent to the Redis
instance and the time to receive a reply is measured. This happens 100
times per second, and stats are updated in a real time in the console:

    $ redis-cli --latency
    min: 0, max: 1, avg: 0.19 (427 samples)

The stats are provided in milliseconds. Usually, the average latency of
a very fast instance tends to be overestimated a bit because of the
latency due to the kernel scheduler of the system running `redis-cli`
itself, so the average latency of 0.19 above may easily be 0.01 or less.
However this is usually not a big problem, since most developers are interested in
events of a few milliseconds or more.

Sometimes it is useful to study how the maximum and average latencies
evolve during time. The `--latency-history` option is used for that
purpose: it works exactly like `--latency`, but every 15 seconds (by
default) a new sampling session is started from scratch:

    $ redis-cli --latency-history
    min: 0, max: 1, avg: 0.14 (1314 samples) -- 15.01 seconds range
    min: 0, max: 1, avg: 0.18 (1299 samples) -- 15.00 seconds range
    min: 0, max: 1, avg: 0.20 (113 samples)^C

Sampling sessions' length can be changed with the `-i <interval>` option.

The most advanced latency study tool, but also the most complex to
interpret for non-experienced users, is the ability to use color terminals
to show a spectrum of latencies. You'll see a colored output that indicates the
different percentages of samples, and different ASCII characters that indicate
different latency figures. This mode is enabled using the `--latency-dist`
option:

    $ redis-cli --latency-dist
    (output not displayed, requires a color terminal, try it!)

There is another pretty unusual latency tool implemented inside `redis-cli`.
It does not check the latency of a Redis instance, but the latency of the
computer running `redis-cli`. This latency is intrinsic to the kernel scheduler, 
the hypervisor in case of virtualized instances, and so forth.

Redis calls it *intrinsic latency* because it's mostly opaque to the programmer.
If the Redis instance has high latency regardless of all the obvious things
that may be the source cause, it's worth to check what's the best your system
can do by running `redis-cli` in this special mode directly in the system you
are running Redis servers on.

By measuring the intrinsic latency, you know that this is the baseline,
and Redis cannot outdo your system. In order to run the CLI
in this mode, use the `--intrinsic-latency <test-time>`. Note that the test time is in seconds and dictates how long the test should run.

    $ ./redis-cli --intrinsic-latency 5
    Max latency so far: 1 microseconds.
    Max latency so far: 7 microseconds.
    Max latency so far: 9 microseconds.
    Max latency so far: 11 microseconds.
    Max latency so far: 13 microseconds.
    Max latency so far: 15 microseconds.
    Max latency so far: 34 microseconds.
    Max latency so far: 82 microseconds.
    Max latency so far: 586 microseconds.
    Max latency so far: 739 microseconds.

    65433042 total runs (avg latency: 0.0764 microseconds / 764.14 nanoseconds per run).
    Worst run took 9671x longer than the average latency.

IMPORTANT: this command must be executed on the computer that runs the Redis server instance, not on a different host. It does not connect to a Redis instance and performs the test locally.

In the above case, the system cannot do better than 739 microseconds of worst
case latency, so one can expect certain queries to occasionally run less than 1 millisecond.

## Remote backups of RDB files

During a Redis replication's first synchronization, the primary and the replica
exchange the whole data set in the form of an RDB file. This feature is exploited
by `redis-cli` in order to provide a remote backup facility that allows a
transfer of an RDB file from any Redis instance to the local computer running
`redis-cli`. To use this mode, call the CLI with the `--rdb <dest-filename>`
option:

    $ redis-cli --rdb /tmp/dump.rdb
    SYNC sent to master, writing 13256 bytes to '/tmp/dump.rdb'
    Transfer finished with success.

This is a simple but effective way to ensure disaster recovery
RDB backups exist of your Redis instance. When using this options in
scripts or `cron` jobs, make sure to check the return value of the command.
If it is non zero, an error occurred as in the following example:

    $ redis-cli --rdb /tmp/dump.rdb
    SYNC with master failed: -ERR Can't SYNC while not connected with my master
    $ echo $?
    1

## Replica mode

The replica mode of the CLI is an advanced feature useful for
Redis developers and for debugging operations.
It allows for the inspection of the content a primary sends to its replicas in the replication
stream in order to propagate the writes to its replicas. The option
name is simply `--replica`. The following is a working example:

    $ redis-cli --replica
    SYNC with master, discarding 13256 bytes of bulk transfer...
    SYNC done. Logging commands from master.
    "PING"
    "SELECT","0"
    "SET","last_name","Enigk"
    "PING"
    "INCR","mycounter"

The command begins by discarding the RDB file of the first synchronization
and then logs each command received in CSV format.

If you think some of the commands are not replicated correctly in your replicas
this is a good way to check what's happening, and also useful information
in order to improve the bug report.

## Performing an LRU simulation

Redis is often used as a cache with [LRU eviction](/topics/lru-cache).
Depending on the number of keys and the amount of memory allocated for the
cache (specified via the `maxmemory` directive), the amount of cache hits
and misses will change. Sometimes, simulating the rate of hits is very
useful to correctly provision your cache.

The `redis-cli` has a special mode where it performs a simulation of GET and SET
operations, using an 80-20% power law distribution in the requests pattern.
This means that 20% of keys will be requested 80% of times, which is a
common distribution in caching scenarios.

Theoretically, given the distribution of the requests and the Redis memory
overhead, it should be possible to compute the hit rate analytically
with a mathematical formula. However, Redis can be configured with
different LRU settings (number of samples) and LRU's implementation, which
is approximated in Redis, changes a lot between different versions. Similarly
the amount of memory per key may change between versions. That is why this
tool was built: its main motivation was for testing the quality of Redis' LRU
implementation, but now is also useful for testing how a given version
behaves with the settings originally intended for deployment.

To use this mode, specify the amount of keys in the test and configure a sensible `maxmemory` setting as a first attempt.

IMPORTANT NOTE: Configuring the `maxmemory` setting in the Redis configuration
is crucial: if there is no cap to the maximum memory usage, the hit will
eventually be 100% since all the keys can be stored in memory. If too many keys are specified with maximum memory, eventually all of the computer RAM will be used. It is also needed to configure an appropriate
*maxmemory policy*; most of the time `allkeys-lru` is selected.

In the following example there is a configured a memory limit of 100MB and an LRU
simulation using 10 million keys.

WARNING: the test uses pipelining and will stress the server, don't use it
with production instances.

    $ ./redis-cli --lru-test 10000000
    156000 Gets/sec | Hits: 4552 (2.92%) | Misses: 151448 (97.08%)
    153750 Gets/sec | Hits: 12906 (8.39%) | Misses: 140844 (91.61%)
    159250 Gets/sec | Hits: 21811 (13.70%) | Misses: 137439 (86.30%)
    151000 Gets/sec | Hits: 27615 (18.29%) | Misses: 123385 (81.71%)
    145000 Gets/sec | Hits: 32791 (22.61%) | Misses: 112209 (77.39%)
    157750 Gets/sec | Hits: 42178 (26.74%) | Misses: 115572 (73.26%)
    154500 Gets/sec | Hits: 47418 (30.69%) | Misses: 107082 (69.31%)
    151250 Gets/sec | Hits: 51636 (34.14%) | Misses: 99614 (65.86%)

The program shows stats every second. In the first seconds the cache starts to be populated. The misses rate later stabilizes into the actual figure that can be expected:

    120750 Gets/sec | Hits: 48774 (40.39%) | Misses: 71976 (59.61%)
    122500 Gets/sec | Hits: 49052 (40.04%) | Misses: 73448 (59.96%)
    127000 Gets/sec | Hits: 50870 (40.06%) | Misses: 76130 (59.94%)
    124250 Gets/sec | Hits: 50147 (40.36%) | Misses: 74103 (59.64%)

A miss rate of 59% may not be acceptable for certain use cases therefor
100MB of memory is not enough. Observe an example using a half gigabyte of memory. After several
minutes the output stabilizes to the following figures:

    140000 Gets/sec | Hits: 135376 (96.70%) | Misses: 4624 (3.30%)
    141250 Gets/sec | Hits: 136523 (96.65%) | Misses: 4727 (3.35%)
    140250 Gets/sec | Hits: 135457 (96.58%) | Misses: 4793 (3.42%)
    140500 Gets/sec | Hits: 135947 (96.76%) | Misses: 4553 (3.24%)

With 500MB there is sufficient space for the key quantity (10 million) and distribution (80-20 style).
