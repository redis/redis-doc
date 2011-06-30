This command is used in order to read and reset the Redis slow queries log.

The Redis Slow Log is a system to log queries that exceeded a specified
execution time. The execution time does not include the I/O operations
like talking with the client, sending the reply and so forth,
but just the time needed to actually execute the command (this is the only
stage of command execution where the thread is blocked and can not serve
other requests in the meantime).

You can configure the slow log with two parameters: one tells Redis
what is the execution time, in microseconds, to exceed in order for the
command to get logged, and the other parameter is the length of the
slow log. When a new command is logged the oldest one is removed from the
queue of logged commands.

The configuration can be done both editing the redis.conf file or 
while the server is running using
the [CONFIG GET](/commands/config-get) and [CONFIG SET](/commands/config-set)
commands.

@Reding the slow log

The slow log is accumulated in memory, so no file is written with information
about the slow command executions. This makes the slow log remarkably fast
at the point that you can enable the logging of all the commands (setting the
*slowlog-log-slower-than* config parameter to zero) with minor performance
hint.

To read the slow log the **SLOWLOG READ** command is used, that returns every
entry in the slow log. It is possible to return only the N most recent entries
passing an additional argument to the command (for instance *SLOWLOG READ 10*).

Note that you need a recent version of redis-cli in order to read the slow
log output, since this uses some feature of the protocol that was not
formerly implemented in redis-cli (deeply nested multi bulk replies).

Example output:

    redis 127.0.0.1:6379> slowlog get
    1) 1) (integer) 1309444013
       2) (integer) 11
       3) 1) "ping"
    2) 1) (integer) 1309444010
       2) (integer) 43
       3) 1) "slowlog"
          2) "get"

Every entry is composed of three fields:
* The unix timestamp at which the logged command was processed.
* The amount of time needed for its execution, in microseconds.
* The array composing the arguments of the command.

It is possible to get just the length of the slow log using the command **SLOWLOG LEN**.

@Resetting the slow log.

You can reset the slow log using the **SLOWLOG RESET** command.
Once deleted the information is lost forever.
