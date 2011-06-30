This command is used in order to read and reset the Redis slow queries log.

## Redis slow log overview

The Redis Slow Log is a system to log queries that exceeded a specified
execution time. The execution time does not include the I/O operations
like talking with the client, sending the reply and so forth,
but just the time needed to actually execute the command (this is the only
stage of command execution where the thread is blocked and can not serve
other requests in the meantime).

You can configure the slow log with two parameters: one tells Redis
what is the execution time, in microseconds, to exceed in order for the
command to get logged, and the other parameter is the length of the
slow log. When a new command is logged and the slow log is already at its
maximum length, the oldest one is removed from the queue of logged commands
in order to make space.

The configuration can be done both editing the redis.conf file or 
while the server is running using
the [CONFIG GET](/commands/config-get) and [CONFIG SET](/commands/config-set)
commands.

## Reding the slow log

The slow log is accumulated in memory, so no file is written with information
about the slow command executions. This makes the slow log remarkably fast
at the point that you can enable the logging of all the commands (setting the
*slowlog-log-slower-than* config parameter to zero) with minor performance
hit.

To read the slow log the **SLOWLOG GET** command is used, that returns every
entry in the slow log. It is possible to return only the N most recent entries
passing an additional argument to the command (for instance **SLOWLOG GET 10**).

Note that you need a recent version of redis-cli in order to read the slow
log output, since this uses some feature of the protocol that was not
formerly implemented in redis-cli (deeply nested multi bulk replies).

## Output format

    redis 127.0.0.1:6379> slowlog get 2
    1) 1) (integer) 14
       2) (integer) 1309448221
       3) (integer) 15
       4) 1) "ping"
    2) 1) (integer) 13
       2) (integer) 1309448128
       3) (integer) 30
       4) 1) "slowlog"
          2) "get"
          3) "100"

Every entry is composed of four fields:
* An unique progressive identifier for every slow log entry.
* The unix timestamp at which the logged command was processed.
* The amount of time needed for its execution, in microseconds.
* The array composing the arguments of the command.

The entries unique ID can be used in order to void processing slow log entries
multiple times (for instance you may have a scripting sending you an email
alert for every new slow log entry).

The ID is never reset in the course of the Redis server execution, only a
server restart will reset it.

## Obtaining the current length of the slow log

It is possible to get just the length of the slow log using the command **SLOWLOG LEN**.

## Resetting the slow log.

You can reset the slow log using the **SLOWLOG RESET** command.
Once deleted the information is lost forever.
