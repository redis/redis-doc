# Inroduction to Eval Scripts

* [Getting Started](evalintro#getting-started)
  * [`Evalsh`](evalintro#codeevalshcode)
  * [EVALSHA in the context of pipelining](evalintro#evalsha-in-the-context-of-pipelining)
* [Script cache semantics](evalintro#script-cache-semantics)
* [The SCRIPT command](evalintro#the-script-command)
* [Scripts with deterministic writes](evalintro#scripts-with-deterministic-writes)
* [Replicating commands instead of scripts](evalintro#replicating-commands-instead-of-scripts)
* [Debugging Eval scripts](evalintro#debugging-eval-scripts)
* [Related Topics](evalintro#related-topics-for-further-reading)
  * [Commands list](evalintro#eval-scripts-command-list)

## Getting Started

`EVAL` scripts is one of the programability option available on Redis.
It allows executing client logic on the server side, `EVAL` script is writen is [Lua](https://www.lua.org/).
The code can be executed using the `EVAL` command.
The following example execute a simple `EVAL` script that returns `HELLO`:

```
> eval "return 'HELLO'" 0
"HELLOE"
```

The first argument of `EVAL` is a Lua 5.1 script.
The script does not need to define a Lua function (and should not).
It is just a Lua program that will run in the context of the Redis server.

The second argument of `EVAL` is the number of arguments that follows the script (starting from the third argument) that represent Redis key names.
In our simple example the script gets no keys, so we simply give `0`.

The arguments can be accessed by Lua using the `!KEYS` global variable in the form of a one-based array (so `KEYS[1]`, `KEYS[2]`, ...).

All the additional arguments should not represent key names and can be accessed by Lua using the `ARGV` global variable,
very similarly to what happens with keys (so `ARGV[1]`, `ARGV[2]`, ...).

The following example should clarify what stated above:

```
> eval "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2], ARGV[3]}" 2 key1 key2 first second third
1) "key1"
2) "key2"
3) "first"
4) "second"
5) "third"
```

Note: as you can see Lua arrays are returned as Redis multi bulk replies,
that is a Redis return type that your client library will likely convert into an Array type in your programming language.

It is possible to call Redis commands from a Lua script using two different Lua
functions:

* [`redis.call()`](topics/lua#rediscallpcall)
* [`redis.pcall()`](topics/lua#rediscallpcall)

[`redis.call()`](topics/lua#rediscallpcall) is similar to [`redis.pcall()`](topics/lua#rediscallpcall),
the only difference is that if a Redis command call will result in an error,
[`redis.call()`](topics/lua#rediscallpcall) will raise a Lua error that in turn will force `EVAL` to return an error to the command caller,
while [`redis.pcall()`](topics/lua#rediscallpcall) will trap the error and return a Lua table representing the error.

The arguments of the [`redis.call()`](topics/lua#rediscallpcall) and [`redis.pcall()`](topics/lua#rediscallpcall)
functions are all the arguments of a well formed Redis command:

```
> eval "return redis.call('set','foo','bar')" 0
OK
```

The above script sets the key `foo` to the string `bar`.
However it violates the `EVAL` command semantics as all the keys that the script uses should be passed using the `!KEYS` array:

```
> eval "return redis.call('set',KEYS[1],'bar')" 1 foo
OK
```

All Redis commands must be analyzed before execution to determine which keys the command will operate on.
In order for this to be true for `EVAL`, keys must be passed explicitly.
This is useful in many ways, but especially to make sure Redis Cluster can forward your request to the appropriate cluster node.

Note this rule is not enforced in order to provide the user with opportunities to abuse the Redis single instance configuration,
at the cost of writing scripts not compatible with Redis Cluster.

Lua scripts can return a value that is converted from the Lua type to the Redis protocol using a set of conversion rules.
For more information about those rules please refer to [`Conversion between Lua and Redis data types`](lua#conversion-between-lua-and-redis-data-types)

### `Evalsh`

The `EVAL` command forces you to send the script body again and again.
Redis does not need to recompile the script every time as it uses an internal caching mechanism,
however paying the cost of the additional bandwidth may not be optimal in many contexts.

On the other hand, defining commands using a special command or via `redis.conf` would be a problem for a few reasons:

*   Different instances may have different implementations of a command.

*   Deployment is hard if we have to make sure all instances contain a given command,
    especially in a distributed environment.

*   Reading application code, the complete semantics might not be clear since the application calls commands defined server side.

In order to avoid these problems while avoiding the bandwidth penalty,
Redis implements the `EVALSHA` command.

`EVALSHA` works exactly like `EVAL`, but instead of having a script as the first argument it has the SHA1 digest of a script.
The behavior is the following:

*   If the server still remembers a script with a matching SHA1 digest, the script is executed.

*   If the server does not remember a script with this SHA1 digest,
    a special error is returned telling the client to use `EVAL` instead.

Example:

```
> set foo bar
OK
> eval "return redis.call('get','foo')" 0
"bar"
> evalsha 6b1bf486c81ceb7edf3c093f4c48582e38c0e791 0
"bar"
> evalsha ffffffffffffffffffffffffffffffffffffffff 0
(error) NOSCRIPT No matching script. Please use EVAL.
```

The client library implementation can always optimistically send `EVALSHA` under the hood even when the client actually calls `EVAL`,
in the hope the script was already seen by the server.
If the `NOSCRIPT` error is returned `EVAL` will be used instead.

Passing keys and arguments as additional `EVAL` arguments is also very useful in this context as the script string remains constant and can be efficiently cached by Redis.

### EVALSHA in the context of pipelining

Care should be taken when executing `EVALSHA` in the context of a pipelined request,
since even in a pipeline the order of execution of commands must be guaranteed.
If `EVALSHA` will return a `NOSCRIPT` error the command can not be reissued later otherwise the order of execution is violated.

The client library implementation should take one of the following approaches:

*   Always use plain `EVAL` when in the context of a pipeline.

*   Accumulate all the commands to send into the pipeline,
    then check for `EVAL` commands and use the `SCRIPT EXISTS` command to check if all the scripts are already defined.
    If not, add `SCRIPT LOAD` commands on top of the pipeline as required,
    and use `EVALSHA` for all the `EVAL` calls.

## Script cache semantics

Executed scripts are guaranteed to be in the script cache of a given execution of a Redis instance forever.
This means that if an `EVAL` is performed against a Redis instance all the subsequent `EVALSHA` calls will succeed.

The reason why scripts can be cached for long time is that it is unlikely for a well written application to have enough different scripts to cause memory problems.
Every script is conceptually like the implementation of a new command,
and even a large application will likely have just a few hundred of them.
Even if the application is modified many times and scripts will change,
the memory used is negligible.

The only way to flush the script cache is by explicitly calling the `SCRIPT FLUSH` command,
which will _completely flush_ the scripts cache removing all the scripts executed so far.

This is usually needed only when the instance is going to be instantiated for another customer or application in a cloud environment.

Also, as already mentioned, restarting a Redis instance flushes the script cache, which is not persistent.
However from the point of view of the client there are only two ways to make sure a Redis instance was not restarted between two different commands.

* The connection we have with the server is persistent and was never closed so far.
* The client explicitly checks the `runid` field in the `INFO` command in order to make sure the server was not restarted and is still the same process.

Practically speaking, for the client it is much better to simply assume that in the context of a given connection,
cached scripts are guaranteed to be there unless an administrator explicitly called the `SCRIPT FLUSH` command.

The fact that the user can count on Redis not removing scripts is semantically useful in the context of pipelining.

For instance an application with a persistent connection to Redis can be sure that if a script was sent once it is still in memory,
so EVALSHA can be used against those scripts in a pipeline without the chance of an error being generated due to an unknown script (we'll see this problem in detail later).

A common pattern is to call `SCRIPT LOAD` to load all the scripts that will appear in a pipeline,
then use `EVALSHA` directly inside the pipeline without any need to check for errors resulting from the script hash not being
recognized.

## The SCRIPT command

Redis offers a SCRIPT command that can be used in order to control the scripting subsystem.
SCRIPT currently accepts three different commands:

*   `SCRIPT FLUSH`

    This command is the only way to force Redis to flush the scripts cache.
    It is most useful in a cloud environment where the same instance can be reassigned to a different user.
    It is also useful for testing client libraries' implementations of the scripting feature.

*   `SCRIPT EXISTS sha1 sha2 ... shaN`

    Given a list of SHA1 digests as arguments this command returns an array of 1 or 0,
    where 1 means the specific SHA1 is recognized as a script already present in the scripting cache,
    while 0 means that a script with this SHA1 was never seen before 
    (or at least never seen after the latest SCRIPT FLUSH command).

*   `SCRIPT LOAD script`

    This command registers the specified script in the Redis script cache.
    The command is useful in all the contexts where we want to make sure that `EVALSHA` will not fail 
    (for instance during a pipeline or MULTI/EXEC operation),
    without the need to actually execute the script.

*   `SCRIPT KILL`

    This command is the only way to interrupt a long-running script that reaches the configured maximum execution time for scripts.
    The SCRIPT KILL command can only be used with scripts that did not modify the dataset during their execution
    (since stopping a read-only script does not violate the scripting engine's guaranteed atomicity).
    See the next sections for more information about long running scripts.

## Scripts with deterministic writes

*Note: starting with Redis 5, scripts are always replicated as effects and not sending the script verbatim. So the following section is mostly applicable to Redis version 4 or older.*

A very important part of scripting is writing scripts that only change the database in a deterministic way.
Scripts executed in a Redis instance are, by default,
propagated to replicas and to the AOF file by sending the script itself -- not the resulting commands.
Since the script will be re-run on the remote host (or when reloading the AOF file), the changes it makes to the database must be reproducible.

The reason for sending the script is that it is often much faster than sending the multiple commands that the script generates.
If the client is sending many scripts to the master,
converting the scripts into individual commands for the replica / AOF would result in too much bandwidth for the replication link or the Append Only File 
(and also too much CPU since dispatching a command received via network is a lot more work for Redis compared to dispatching a command invoked by Lua scripts).

Normally replicating scripts instead of the effects of the scripts makes sense,
however not in all the cases. So starting with Redis 3.2,
the scripting engine is able to, alternatively,
replicate the sequence of write commands resulting from the script execution, instead of replication the script itself.
See the next section for more information.

In this section we'll assume that scripts are replicated by sending the whole script.
Let's call this replication mode **whole scripts replication**.

The main drawback with the *whole scripts replication* approach is that scripts are required to have the following property:

* The script must always execute the same Redis _write_ commands with the same arguments given the same input data set.
  Operations performed by the script cannot depend on any hidden (non-explicit) information or state that may change as script execution proceeds or between different executions of the script,
  nor can it depend on any external input from I/O devices.

Things like using the system time, calling Redis random commands like `RANDOMKEY`,
or using Lua's random number generator, could result in scripts that will not always evaluate in the same way.

In order to enforce this behavior in scripts Redis does the following:

* Lua does not export commands to access the system time or other external state.
* Redis will block the script with an error if a script calls a Redis command able to alter the data set **after** a Redis _random_ command like `RANDOMKEY`, `SRANDMEMBER`, `TIME`.
  This means that if a script is read-only and does not modify the data set it is free to call those commands.
  Note that a _random command_ does not necessarily mean a command that uses random numbers: any non-deterministic command is considered a random command 
  (the best example in this regard is the `TIME` command).
* In Redis version 4, commands that may return elements in random order, 
  like `SMEMBERS` (because Redis Sets are _unordered_) have a different behavior when called from Lua,
  and undergo a silent lexicographical sorting filter before returning data to Lua scripts.
  So `redis.call("smembers",KEYS[1])` will always return the Set elements in the same order,
  while the same command invoked from normal clients may return different results even if the key contains exactly the same elements.
  However starting with Redis 5 there is no longer such ordering step,
  because Redis 5 replicates scripts in a way that no longer needs non-deterministic commands to be converted into deterministic ones.
  In general, even when developing for Redis 4, never assume that certain commands in Lua will be ordered,
  but instead rely on the documentation of the original command you call to see the properties it provides.
* Lua's pseudo-random number generation function `math.random` is modified to always use the same seed every time a new script is executed.
  This means that calling `math.random` will always generate the same sequence of numbers every time a script is executed if `math.randomseed` is not used.

However the user is still able to write commands with random behavior using the following simple trick.
Imagine I want to write a Redis script that will populate a list with N random integers.

I can start with this small Ruby program:

```
require 'rubygems'
require 'redis'

r = Redis.new

RandomPushScript = <<EOF
    local i = tonumber(ARGV[1])
    local res
    while (i > 0) do
        res = redis.call('lpush',KEYS[1],math.random())
        i = i-1
    end
    return res
EOF

r.del(:mylist)
puts r.eval(RandomPushScript,[:mylist],[10,rand(2**32)])
```

Every time this script is executed the resulting list will have exactly the
following elements:

```
> lrange mylist 0 -1
 1) "0.74509509873814"
 2) "0.87390407681181"
 3) "0.36876626981831"
 4) "0.6921941534114"
 5) "0.7857992587545"
 6) "0.57730350670279"
 7) "0.87046522734243"
 8) "0.09637165539729"
 9) "0.74990198051087"
1)  "0.17082803611217"
```

In order to make it deterministic, but still be sure that every invocation of the script will result in different random elements,
we can simply add an additional argument to the script that will be used to seed the Lua pseudo-random number generator.
The new script is as follows:

```
RandomPushScript = <<EOF
    local i = tonumber(ARGV[1])
    local res
    math.randomseed(tonumber(ARGV[2]))
    while (i > 0) do
        res = redis.call('lpush',KEYS[1],math.random())
        i = i-1
    end
    return res
EOF

r.del(:mylist)
puts r.eval(RandomPushScript,1,:mylist,10,rand(2**32))
```

What we are doing here is sending the seed of the PRNG as one of the arguments.
The script output will always be the same given the same arguments (our requirement) but we are changing one of the arguments at every invocation,
generating the random seed client-side.
The seed will be propagated as one of the arguments both in the replication link and in the Append Only File,
guaranteeing that the same changes will be generated when the AOF is reloaded or when the replica processes the script.

Note: an important part of this behavior is that the PRNG that Redis implements as `math.random` and `math.randomseed` is guaranteed to have the same output regardless of the architecture of the system running Redis.
32-bit, 64-bit, big-endian and little-endian systems will all produce the same output.

## Replicating commands instead of scripts

*Note: starting with Redis 5, the replication method described in this section (scripts effects replication) is the default and does not need to be explicitly enabled.*

Starting with Redis 3.2, it is possible to select an alternative replication method.
Instead of replicating whole scripts, we can just replicate single write commands generated by the script.
We call this **script effects replication**.

In this replication mode, while Lua scripts are executed, Redis collects all the commands executed by the Lua scripting engine that actually modify the dataset.
When the script execution finishes, the sequence of commands that the script generated are wrapped into a MULTI / EXEC transaction and are sent to the replicas and AOF.

This is useful in several ways depending on the use case:

* When the script is slow to compute, but the effects can be summarized by a few write commands, it is a shame to re-compute the script on the replicas or when reloading the AOF.
  In this case it is much better to replicate just the effects of the script.
* When script effects replication is enabled, the restrictions on non-deterministic functions are removed.
  You can, for example, use the `TIME` or `SRANDMEMBER` commands inside your scripts freely at any place.
* The Lua PRNG in this mode is seeded randomly on every call.

To enable script effects replication you need to issue the following Lua command before the script performs a write:

    redis.replicate_commands()

The function returns true if script effects replication was enabled;
otherwise, if the function was called after the script already called a write command,
it returns false, and normal whole script replication is used.

## Debugging Eval scripts

Starting with Redis 3.2, Redis has support for native Lua debugging.
The Redis Lua debugger is a remote debugger consisting of a server,
which is Redis itself, and a client, which is by default `redis-cli`.

The Lua debugger is described in the [Lua scripts debugging](/topics/ldb) section of the Redis documentation.

## Related topics for further reading

* [Redis Programability](/topics/programability)
* [Redis Lua API](/topics/lua)
* [Redis Functions](/topics/function)

### Eval Scripts Command List

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