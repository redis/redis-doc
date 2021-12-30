# Redis Programability
Programability in Redis allows the user to send functionality (scritps) into Redis that will run on the sever where the data leaves.
This can reduce network hops and improve overal perfromance.
It can also enrich the API provided by Redis with a user define API,
and allow implementing a schema over Redis data structures (updates multiple keys together, keep keys in sync).

Currently, scripts can only be written in [Lua](https://www.lua.org/).
Redis runs an embeded Lua 5.1 interpreter that is used to run the user scripts.
The full Lua API provided to the user is documented on [Redis Lua API](/topics/lua).

In addition, Redis provides two ways to run the scripts:

* [Redis Functions](/topics/function) (available on Redis 7 and above)
* [Redis Eval Scripts](/topics/evalintro)

Redis guarantees that a script is executed in an atomic way:
no other script or Redis command will be executed while a script is being executed.
This semantic is similar to the one of `MULTI` / `EXEC`.
From the point of view of all the other clients the effects of a script are either still not visible or already completed.

However this also means that executing slow scripts is not a good idea.
It is not hard to create fast scripts, as the script overhead is very low,
but if you are going to use slow scripts you should be aware that while the script is running no other client can execute commands.

## Sandbox and maximum execution time

Scripts should never try to access the external system, like the file system or any other system call.
A script should only operate on Redis data and passed arguments.

Scripts are also subject to a maximum execution time (five seconds by default).
This default timeout is huge since a script should usually run in under a millisecond.
The limit is mostly to handle accidental infinite loops created during development.

It is possible to modify the maximum time a script can be executed with millisecond precision,
either via `redis.conf` or using the CONFIG GET / CONFIG SET command.
The configuration parameter affecting max execution time is called `script-time-limit`.

When a script reaches the timeout it is not automatically terminated by Redis since this violates the contract Redis has with the scripting engine to ensure that scripts are atomic.
Interrupting a script means potentially leaving the dataset with half-written data.
For this reasons when a script executes for more than the specified time the following happens:

* Redis logs that a script is running too long.
* It starts accepting commands again from other clients,
  but will reply with a BUSY error to all the clients sending normal commands.
  The only allowed commands in this status are `SCRIPT KILL`, `FUNCTION KILL` and `SHUTDOWN NOSAVE`.
* It is possible to terminate a script that executes only read-only commands using the `SCRIPT KILL` and `FUNCTION KILL` commands.
  This does not violate the scripting semantic as no data was yet written to the dataset by the script.
* If the script already called write commands the only allowed command becomes `SHUTDOWN NOSAVE` that stops the server without saving the current data set on disk (basically the server is aborted).

## Running Scripts under low memory conditions

When the memory usage in Redis exceeds the `maxmemory` limit,
the first write command encountered in the script that uses additional memory will cause the script to abort (unless [`redis.pcall`](lua#rediscallpcall) was used).
However, one thing to caution here is that if the first write command does not use additional memory such as DEL, LREM, or SREM, etc,
Redis will allow it to run and all subsequent commands in the script will execute to completion for atomicity.
If the subsequent writes in the script generate additional memory, the Redis memory usage can go over `maxmemory`.

Another possible way for Lua script to cause Redis memory usage to go above `maxmemory` happens when the script execution starts when Redis is slightly below `maxmemory` so the first write command in the script is allowed.
As the script executes, subsequent write commands continue to generate memory and causes the Redis server to go above `maxmemory`.

In those scenarios, it is recommended to configure the `maxmemory-policy` not to use `noeviction`.
Also Lua scripts should be short so that evictions of items can happen in between Lua scripts.

## Commands list

### Eval Scripts

* `EVAL`
* `EVALSHA`
* `EVALSHA_RO`
* `EVAL_RO`
* `SCRIPT DEBUG`
* `SCRIPT EXISTS`
* `SCRIPT FLUSH`
* `SCRIPT HELP`
* `SCRIPT KILL`
* `SCRIPT LOAD`

### Functions

* `FCALL`
* `FCALL_RO`
* `FUNCTION`
* `FUNCTION CREATE`
* `FUNCTION DELETE`
* `FUNCTION DUMP`
* `FUNCTION FLUSH`
* `FUNCTION HELP`
* `FUNCTION INFO`
* `FUNCTION KILL`
* `FUNCTION LIST`
* `FUNCTION RESTORE`
* `FUNCTION STATS`