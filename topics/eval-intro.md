# Introduction to Eval Scripts

Starting with Redis 2.6, users can execute scripted logic in the server.
This feature enables the composition of workflows that clients can instruct the server to execute.
Scripts can employ programmatic control structures and use most of the [commands](/commands) while executing to access the database.
Because scripts execute in the server, reading and writing data from scripts is very efficient.

Redis guarantees the script's atomic execution.
While executing the script, all server activities are blocked during its entire runtime.
These semantics mean that all of the script's effects either have yet to happen or had already happened.

Scripting offers several properties that can be valuable in many cases.
These include:

* Providing locality by executing logic where data lives. Data locality reduces overall latency and saves networking resources.
* Blocking semantics that ensure the script's atomic execution.
* Enabling the composition of simple capabilities that are either missing from Redis or are too niche to a part of it.

The core use cases for [Eval Scripts](/topics/eval-intro) is running part of your application logic inside Redis.
Such script can perform conditional updates across multiple keys, possibly combining several different data types atomically.

Scripts are executed in Redis by an embedded execution engine.
Presently, Redis supports a single scripting engine, the [Lua 5.1](https://www.lua.org/) interpreter.
Please refer to the [Redis Lua API Reference](/topics/lua-api) page for complete documentation.

Although the server executes them, Eval scripts are regarded as a part of the client-side application, which is why they're not named, versioned, or persisted.
So all scripts may need to be reloaded by the application at any time if missing (after a server restart, fail-over to a replica, etc.).
As of version 7.0, [Redis Functions](/topics/functions-intro) offer an alternative approach to programmability which allow the server itself to be extended with additional programmed logic.

## Getting started

We'll start scripting with Redis by using the `EVAL` command.

Here's our first example:

```
> EVAL "return 'Hello, scripting!'" 0
"Hello, scripting!"
```

In this example, `EVAL` takes two arguments.
The first argument is a string that consists of the script's Lua source code.
The script doesn't need to include any definitions of Lua function.
It is just a Lua program that will run in the Redis engine's context.

The second argument is the number of arguments that follow the script's body, starting from the third argument, representing Redis key names.
In this example, we used the value _0_ because we didn't provide the script with any arguments, whether the names of keys or not.

## Script parameterization

It is possible, although highly ill-advised, to have the application dynamically generate script source code per its needs.
For example, the application could send these two entirely different, but in the same time perfectly identical scripts:

```
redis> EVAL "return 'Hello'" 0
"Hello"
redis> EVAL "return 'Scripting!'" 0
"Scripting!"
```

Although this mode of operation isn't blocked by Redis, it is an anti-pattern due to script cache considerations (more on the topic below).
Instead of having your application generate subtle variations of the same scripts, you can parametrize them and pass any arguments needed for to execute them.

The following example demonstrates how to achieve the same effects as above, but via parameterization:

```
redis> EVAL "return ARGV[1]" 0 Hello
"Hello"
redis> EVAL "return ARGV[1]" 0 Parameterization!
"Parameterization!"
```

At this point, it is essential to understand the distinction Redis makes between input arguments that are names of keys and those that aren't.

While key names in Redis are just strings, unlike any other string values, these represent keys in the database.
The name of a key is a fundamental concept in Redis and is the basis for operating the Redis Cluster.

**Important:**
to ensure the correct execution of scripts, both in standalone and clustered deployments, all names of keys that a script accesses must be explicitly provided as input key arguments.
The script **should only** access keys whose names are given as input arguments.
Scripts **should never** access keys with programmatically-generated names or based on the contents of data structures stored in the database.

Any input to the function that isn't the name of a key is a regular input argument.

In the example above, both _Hello_ and _Parameterization!_ regular input arguments for the script.
Because the script doesn't touch any keys, we use the numerical argument _0_ to specify there are no key name arguments.
The execution context makes arguments available to the script through [_KEYS_](lua-api#the-keys-global-variable) and [_ARGV_](lua-api#the-argv-global-variable) global runtime variables.
The _KEYS_ table is pre-populated with all key name arguments provided to the script before its execution, whereas the _ARGV_ table serves a similar purpose but for regular arguments.

The following attempts to demonstrate the distribution of input arguments between the scripts _KEYS_ and _ARGV_ runtime global variables:


```
redis> EVAL "return { KEYS[1], KEYS[2], ARGV[1], ARGV[2], ARGV[3] }" 2 key1 key2 arg1 arg2 arg3
1) "key1"
2) "key2"
3) "arg1"
4) "arg2"
5) "arg3"
```

**Note:**
as can been seen above, Lua's table arrays are returned as [RESP2 array replies](/topics/protocol#resp-arrays), so it is likely that your client's library will convert it to the native array data type in your programming language.
Please refer to the rules that govern [data type conversion](/topics/lua-api#data-type-conversion) for more pertinent information.

## Interacting with Redis from a script

It is possible to call Redis commands from a Lua script either via [`redis.call()`](/topics/lua-api#redis.call) or [`redis.pcall()`](/topics/lua-api#redis.pcall).

The two are nearly identical.
Both execute a Redis command along with its provided arguments, if these represent a well-formed command.
However, the difference between the two functions lies in the manner in which runtime errors (such as syntax errors, for example) are handled.
Errors raised from calling `redis.call()` function are returned directly to the client that had executed it.
Conversely, errors encountered when calling the `redis.pcall()` function are returned to the script's execution context instead for possible handling.

For example, consider the following:

```
> EVAL "return redis.call('SET', KEYS[1], ARGV[1])" 1 foo bar
OK
```
The above script accepts one key name and one value as its input arguments.
When executed, the script calls the `SET` command to set the input key, _foo_, with the string value "bar".

## Script cache

Until this point, we've used the `EVAL` command to run our script.

Whenever we call `EVAL`, we also include the script's source code with the request.
Repeatedly calling `EVAL` to execute the same set of parameterized scripts, wastes both network bandwidth and also has some overheads in Redis.
Naturally, saving on network and compute resources is key, so, instead, Redis provides a caching mechanism for scripts.

Every script you execute with `EVAL` is stored in a dedicated cache that the server keeps.
The cache's contents are organized by the scripts' SHA1 digest sums, so the SHA1 digest sum of a script uniquely identifies it in the cache.
You can verify this behavior by running `EVAL` and calling `INFO` afterward.
You'll notice that the _used_memory_scripts_eval_ and _number_of_cached_scripts_ metrics grow with every new script that's executed.

As mentioned above, dynamically-generated scripts are an anti-pattern.
Generating scripts during the applicaiton's runtime may, and probably will, exhaust the host's memory resources for caching them.
Instead, scripts should be as generic as possible and provide customized execution via their arguments.

A script is loaded to the server's cache by calling the `SCRIPT LOAD` command and providing its source code.
The server doesn't executed the script, but instead just compiles and loads it to the server's cache.
Once loaded, you can execute the cached script with the SHA1 digest returned from the server.

Here's an example of loading and then executing a cached script:

```
redis> SCRIPT LOAD "return 'Immabe a cached script'"
"c664a3bf70bd1d45c4284ffebb65a6f2299bfc9f"
redis> EVALSHA c664a3bf70bd1d45c4284ffebb65a6f2299bfc9f 0
"Immabe a cached script"
```

### Cache volatility

The Redis script cache is **always volatile**.
It isn't considered as a part of the database and is **not persisted**.
The cache may be cleared when the server restarts, during fail-over when a replica assumes the master role, or explicitly by `SCRIPT FLUSH`.
That means that cached scripts are ephemeral, and the cache's contents can be lost at any time.

Applications that use scripts should always call `EVALSHA` to execute them.
The server returns an error if the script's SHA1 digest is not in the cache.
For example:

```
redis> EVALSHA ffffffffffffffffffffffffffffffffffffffff 0
(error) NOSCRIPT No matching script
```

In this case, the application should first load it with `SCRIPT LOAD` and then call `EVALSHA` once more to run the cached script by its SHA1 sum.
Most of [Redis' clients](/clients) already provide utility APIs for doing that automatically.
Please consult your client's documentation regarding the specific details.

### `EVALSHA` in the context of pipelining

Special care should be given executing `EVALSHA` in the context of a [pipelined request](/topics/pipelining).
The commands in a pipelined request run in the order they are sent, but other clients' commands may be interleaved for execution between these.
Because of that, the `NOSCRIPT` error can return from a pipelined request but can't be handled.

Therefore, a client library's implementation should revert to using plain `EVAL` of parameterized in the context of a pipeline.

### Script cache semantics

During normal operation, an application's scripts are meant to stay indefintely in the cache (that is, until the server is restarted or the cache being flushed).
The underlying reasoning is that the script cache contents of a well-written application are unlikely to grow continuously.
Even large applications that use hundereds of cached scripts shouldn't be and issue in terms of cache memory usage. 

The only way to flush the script cache is by explicitly calling the `SCRIPT FLUSH` command.
Running the command will _completely flush_ the scripts cache, removing all the scripts executed so far.
Typically, this is only needed when the instance is going to be instantiated for another customer or application in a cloud environment.

Also, as already mentioned, restarting a Redis instance flushes the non-persistent script cache.
However, from the point of view of the Redis client, there are only two ways to make sure that a Redis instance was not restarted between two different commands:

* The connection we have with the server is persistent and was never closed so far.
* The client explicitly checks the `runid` field in the `INFO` command to ensure the server was not restarted and is still the same process.

Practically speaking, it is much simpler for the client to assume that in the context of a given connection, cached scripts are guaranteed to be there unless the administrator explicitly invoked the `SCRIPT FLUSH` command.
The fact that the user can count on Redis to retain cached scripts is semantically helpful in the context of pipelining.

## The `SCRIPT` command

The Redis `SCRIPT` provides several ways for controlling the scripting subsystem.
These are:

* `SCRIPT FLUSH`: this command is the only way to force Redis to flush the scripts cache.
  It is most useful in environments where the same Redis instance is reassigned to different uses.
  It is also helpful for testing client libraries' implementations of the scripting feature.

* `SCRIPT EXISTS`: given one or more SHA1 digests as arguments, this command returns an array of _1_'s and _0_'s.
  _1_ means the specific SHA1 is recognized as a script already present in the scripting cache. _0_'s meaning is that a script with this SHA1 wasn't loaded before (or at least never since the latest call to `SCRIPT FLUSH`).

* `SCRIPT LOAD script`: this command registers the specified script in the Redis script cache. 
  It is a useful command in all the contexts where we want to ensure that `EVALSHA` doesn't not fail (for instance, in a pipeline or when called from a [`MULTI`/`EXEC` transaction](/topics/transactions)), without the need to execute the script.

* `SCRIPT KILL`: this command is the only way to interrupt a long-running script (a.k.a slow script), short of shutting down the server.
  A script is deemed as slow once its execution's duration exceeds the configured [maximum execution time](/topics/programmability#maximum-execution-time) threshold.
  The `SCRIPT KILL` command can be used only with scripts that did not modify the dataset during their execution (since stopping a read-only script does not violate the scripting engine's guaranteed atomicity).

* `SCRIPT DEBUG`: controls use of the built-in [Redis Lua scripts debugger](/topics/ldb).

## Script replication

In standalone deployments, a single Redis instance called _master_ manages the entire database.
A [clustered deployment](/topics/cluster-tutorial) has at least three masters managing the sharded database.
Redis uses [replication](/topics/replication) to maintain one or more replicas, or exact copies, for any given master.

Because scripts can modify the data, Redis ensures all write operations performed by a script are also sent to replicas to maintain consistency.
There are two conceptual approaches when it comes to script replication:

1. Verbatim replication: the master sends the script's source code to the replicas.
   Replicas then execute the script and apply the write effects.
   This mode can save on replication bandwidth in cases where short scripts generate many commands (for example, a _for_ loop).
   However, this replication mode means that replicas redo the same work done by the master, which is wasteful.
   More importantly, it also requires [all write scripts to be deterministic](#scripts-with-deterministic-writes).
1. Effects replication: only the script's data-modifying commands are replicated.
   Replicas then run the commands without executing any scripts.
   While potentially more lengthy in terms of network traffic, this replication mode is deterministic by definition and therefore doesn't require special consideration.

Verbatim script replication was the only mode supported until Redis 3.2, in which effects replication was added.
The _lua-replicate-commands_ configuration directive and [`redis.replicate_commands()`](/topics/lua-api#redis.replicate_commands) Lua API can be used to enable it.

In Redis 5.0, effects replication became the default mode.
As of Redis 7.0, verbatim replication is no longer supported.

### Replicating commands instead of scripts

Starting with Redis 3.2, it is possible to select an alternative replication method.
Instead of replicating whole scripts, we can replicate the write commands generated by the script.
We call this **script effects replication**.

**Note:**
starting with Redis 5.0, script effects replication is the default mode and does not need to be explicitly enabled.

In this replication mode, while Lua scripts are executed, Redis collects all the commands executed by the Lua scripting engine that actually modify the dataset.
When the script execution finishes, the sequence of commands that the script generated are wrapped into a [`MULTI`/`EXEC` transaction](/topics/transactions) and are sent to the replicas and AOF.

This is useful in several ways depending on the use case:

* When the script is slow to compute, but the effects can be summarized by a few write commands, it is a shame to re-compute the script on the replicas or when reloading the AOF.
  In this case, it is much better to replicate just the effects of the script.
* When script effects replication is enabled, the restrictions on non-deterministic functions are removed.
  You can, for example, use the `TIME` or `SRANDMEMBER` commands inside your scripts freely at any place.
* The Lua PRNG in this mode is seeded randomly on every call.

Unless already enabled by the server's configuration or defaults (before Redis 7.0), you need to issue the following Lua command before the script performs a write:

```lua
redis.replicate_commands()
```

The [`redis.replicate_commands()`](/topics/lua-api#redis.replicate_commands) function returns _true) if script effects replication was enabled;
otherwise, if the function was called after the script already called a write command,
it returns _false_, and normal whole script replication is used.

This function is deprecated as of Redis 7.0, and while you can still call it, it will always succeed. 

### Scripts with deterministic writes

**Note:**
Starting with Redis 5.0, script replication is by default effect-based rather than verbatim.
In Redis 7.0, verbatim script replication had been removed entirely.
The following section only applies to versions lower than Redis 7.0 when not using effect-based script replication.

An important part of scripting is writing scripts that only change the database in a deterministic way.
Scripts executed in a Redis instance are, by default until version 5.0, propagated to replicas and to the AOF file by sending the script itself -- not the resulting commands.
Since the script will be re-run on the remote host (or when reloading the AOF file), its changes to the database must be reproducible.

The reason for sending the script is that it is often much faster than sending the multiple commands that the script generates.
If the client is sending many scripts to the master, converting the scripts into individual commands for the replica / AOF would result in too much bandwidth for the replication link or the Append Only File (and also too much CPU since dispatching a command received via the network is a lot more work for Redis compared to dispatching a command invoked by Lua scripts).

Normally replicating scripts instead of the effects of the scripts makes sense, however not in all the cases.
So starting with Redis 3.2, the scripting engine is able to, alternatively, replicate the sequence of write commands resulting from the script execution, instead of replication the script itself.

In this section, we'll assume that scripts are replicated verbatim by sending the whole script.
Let's call this replication mode **verbatim scripts replication**.

The main drawback with the *whole scripts replication* approach is that scripts are required to have the following property:
the script **always must** execute the same Redis _write_ commands with the same arguments given the same input data set.
Operations performed by the script can't depend on any hidden (non-explicit) information or state that may change as the script execution proceeds or between different executions of the script.
Nor can it depend on any external input from I/O devices.

Acts such as using the system time, calling Redis commands that return random values (e.g., `RANDOMKEY`), or using Lua's random number generator, could result in scripts that will not evaluate consistently.

To enforce the deterministic behavior of scripts, Redis does the following:

* Lua does not export commands to access the system time or other external states.
* Redis will block the script with an error if a script calls a Redis command able to alter the data set **after** a Redis _random_ command like `RANDOMKEY`, `SRANDMEMBER`, `TIME`.
  That means that read-only scripts that don't modify the dataset can call those commands.
  Note that a _random command_ does not necessarily mean a command that uses random numbers: any non-deterministic command is considered as a random command (the best example in this regard is the `TIME` command).
* In Redis version 4.0, commands that may return elements in random order, such as `SMEMBERS` (because Redis Sets are _unordered_), exhibit a different behavior when called from Lua,
and undergo a silent lexicographical sorting filter before returning data to Lua scripts.
  So `redis.call("SMEMBERS",KEYS[1])` will always return the Set elements in the same order, while the same command invoked by normal clients may return different results even if the key contains exactly the same elements.
  However, starting with Redis 5.0, this ordering is no longer performed because replicating effects circumvents this type of non-determinism.
  In general, even when developing for Redis 4.0, never assume that certain commands in Lua will be ordered, but instead rely on the documentation of the original command you call to see the properties it provides.
* Lua's pseudo-random number generation function `math.random` is modified and always uses the same seed for every execution.
  This means that calling [`math.random`](lua-api#runtime-libraries) will always generate the same sequence of numbers every time a script is executed (unless `math.randomseed` is used).

All that said, you can still use commands that write and random behavior with a simple trick.
Imagine that you want to write a Redis script that will populate a list with N random integers.

The initial implementation in Ruby could look like this:

```
require 'rubygems'
require 'redis'

r = Redis.new

RandomPushScript = <<EOF
    local i = tonumber(ARGV[1])
    local res
    while (i > 0) do
        res = redis.call('LPUSH',KEYS[1],math.random())
        i = i-1
    end
    return res
EOF

r.del(:mylist)
puts r.eval(RandomPushScript,[:mylist],[10,rand(2**32)])
```

Every time this code runs, the resulting list will have exactly the
following elements:

```
redis> LRANGE mylist 0 -1
 1) "0.74509509873814"
 2) "0.87390407681181"
 3) "0.36876626981831"
 4) "0.6921941534114"
 5) "0.7857992587545"
 6) "0.57730350670279"
 7) "0.87046522734243"
 8) "0.09637165539729"
 9) "0.74990198051087"
10) "0.17082803611217"
```

To make the script both deterministic and still have it produce different random elements,
we can add an extra argument to the script that's the seed to Lua's pseudo-random number generator.
The new script is as follows:

```
RandomPushScript = <<EOF
    local i = tonumber(ARGV[1])
    local res
    math.randomseed(tonumber(ARGV[2]))
    while (i > 0) do
        res = redis.call('LPUSH',KEYS[1],math.random())
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

## Debugging Eval scripts

Starting with Redis 3.2, Redis has support for native Lua debugging.
The Redis Lua debugger is a remote debugger consisting of a server, which is Redis itself, and a client, which is by default [`redis-cli`](/topics/rediscli).

The Lua debugger is described in the [Lua scripts debugging](/topics/ldb) section of the Redis documentation.

## Execution under low memory conditions

When memory usage in Redis exceeds the `maxmemory` limit, the first write command encountered in the script that uses additional memory will cause the script to abort (unless [`redis.pcall`](/topics/lua-api#redis.pcall) was used).

However, an exception to the above is when the script's first write command does not use additional memory, as is the case with  (for example, `DEL` and `LREM`).
In this case, Redis will allow all commands in the script to run to ensure atomicity.
If subsequent writes in the script consume additional memory, Redis' memory usage can exceed the threshold set by the `maxmemory` configuration directive.

Another scenario in which a script can cause memory usage to cross the `maxmemory` threshold is when the execution begins when Redis is slightly below `maxmemory`, so the script's first write command is allowed.
As the script executes, subsequent write commands consume more memory leading to the server using more RAM than the configured `maxmemory` directive.

In those scenarios, you should consider setting the `maxmemory-policy` configuration directive to any values other than `noeviction`.
In addition, Lua scripts should be as fast as possible so that eviction can kick in between executions.

Note that you can change this behaviour by using [flags](#eval-flags)

## Eval Flags

Normally, when you run an Eval script, the server does not know how it accesses the database.
By default, Redis assumes that all scripts read and write data.
However, starting with Redis 7.0, there's a way to declare flags when creating a script in order to tell Redis how it should behave.

The way to do that us using a Shebang statement on the first line of the script like so:

```
#!lua flags=no-writes,allow-stale
local x = redis.call('get','x')
return x
```

Note that as soon as Redis sees the `#!` comment, it'll treat the script as if it declares flags, even if no flags are defined,
it still has a different set of defaults compared to a script without a `#!` line.

Please refer to [Script flags](lua-api#script_flags) to learn about the various scripts and the defaults.
