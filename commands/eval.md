Introduction to EVAL
---

`EVAL` and `EVALSHA` are used to evaluate scripts using the Lua interpreter
built into Redis starting from version 2.6.0.

The first argument of `EVAL` is a Lua 5.1 script. The script does not need
to define a Lua function (and should not).  It is just a Lua program that will run in the context of the Redis server.

The second argument of `EVAL` is the number of arguments that follows
the script (starting from the third argument) that represent Redis key names.
This arguments can be accessed by Lua using the `KEYS` global variable in
the form of a one-based array (so `KEYS[1]`, `KEYS[2]`, ...).

All the additional arguments should not represent key names and can
be accessed by Lua using the `ARGV` global variable, very similarly to
what happens with keys (so `ARGV[1]`, `ARGV[2]`, ...).

The following example should clarify what stated above:

    > eval "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}" 2 key1 key2 first second
    1) "key1"
    2) "key2"
    3) "first"
    4) "second"

Note: as you can see Lua arrays are returned as Redis multi bulk
replies, that is a Redis return type that your client library will
likely convert into an Array type in your programming language.

It is possible to call Redis commands from a Lua script using two different
Lua functions:

* `redis.call()`
* `redis.pcall()`

`redis.call()` is similar to `redis.pcall()`, the only difference is that if a
Redis command call will result into an error, `redis.call()` will raise a Lua
error that in turn will force `EVAL` to return an error to the command caller,
while `redis.pcall` will trap the error returning a Lua table representing the
error.

The arguments of the `redis.call()` and `redis.pcall()` functions are simply
all the arguments of a well formed Redis command:

    > eval "return redis.call('set','foo','bar')" 0
    OK

The above script actually sets the key `foo` to the string `bar`.
However it violates the `EVAL` command semantics as all the keys that the
script uses should be passed using the KEYS array, in the following way:

    > eval "return redis.call('set',KEYS[1],'bar')" 1 foo
    OK

The reason for passing keys in the proper way is that, before `EVAL` all
the Redis commands could be analyzed before execution in order to
establish what keys the command will operate on.

In order for this to be true for `EVAL` also keys must be explicit.
This is useful in many ways, but especially in order to make sure Redis Cluster
is able to forward your request to the appropriate cluster node (Redis
Cluster is a work in progress, but the scripting feature was designed
in order to play well with it). However this rule is not enforced in order to provide the user with opportunities to abuse the Redis single instance configuration, at the cost of writing scripts not compatible with Redis Cluster.

Lua scripts can return a value, that is converted from the Lua type to the Redis protocol using a set of conversion rules.

Conversion between Lua and Redis data types
---

Redis return values are converted into Lua data types when Lua calls a
Redis command using call() or pcall(). Similarly Lua data types are
converted into the Redis protocol when a Lua script returns a value, so that
scripts can control what `EVAL` will return to the client.

This conversion between data types is designed in a way that if
a Redis type is converted into a Lua type, and then the result is converted
back into a Redis type, the result is the same as of the initial value.

In other words there is a one-to-one conversion between Lua and Redis types.
The following table shows you all the conversions rules:

**Redis to Lua** conversion table.

* Redis integer reply -> Lua number
* Redis bulk reply -> Lua string
* Redis multi bulk reply -> Lua table (may have other Redis data types nested)
* Redis status reply -> Lua table with a single `ok` field containing the status
* Redis error reply -> Lua table with a single `err` field containing the error
* Redis Nil bulk reply and Nil multi bulk reply -> Lua false boolean type

**Lua to Redis** conversion table.

* Lua number -> Redis integer reply
* Lua string -> Redis bulk reply
* Lua table (array) -> Redis multi bulk reply
* Lua table with a single `ok` field -> Redis status reply
* Lua table with a single `err` field -> Redis error reply
* Lua boolean false -> Redis Nil bulk reply.

There is an additional Lua-to-Redis conversion rule that has no corresponding
Redis to Lua conversion rule:

 * Lua boolean true -> Redis integer reply with value of 1.

Here are a few conversion examples:

    > eval "return 10" 0
    (integer) 10

    > eval "return {1,2,{3,'Hello World!'}}" 0
    1) (integer) 1
    2) (integer) 2
    3) 1) (integer) 3
       2) "Hello World!"

    > eval "return redis.call('get','foo')" 0
    "bar"

The last example shows how it is possible to receive the exact return value of
`redis.call()` or `redis.pcall()` from Lua that would be returned if the
command was called directly.

Atomicity of scripts
---

Redis uses the same Lua interpreter to run all the commands. Also Redis
guarantees that a script is executed in an atomic way: no other script
or Redis command will be executed while a script is being executed.
This semantics is very similar to the one of `MULTI` / `EXEC`.
From the point of view of all the other clients the effects of a script
are either still not visible or already completed.

However this also means that executing slow scripts is not a good idea.
It is not hard to create fast scripts, as the script overhead is very low,
but if you are going to use slow scripts you should be aware that while the
script is running no other client can execute commands since the server
is busy.

Error handling
---

As already stated, calls to `redis.call()` resulting in a Redis command error
will stop the execution of the script and will return the error, in a
way that makes it obvious that the error was generated by a script:

    > del foo
    (integer) 1
    > lpush foo a
    (integer) 1
    > eval "return redis.call('get','foo')" 0
    (error) ERR Error running script (call to f_6b1bf486c81ceb7edf3c093f4c48582e38c0e791): ERR Operation against a key holding the wrong kind of value

Using the `redis.pcall()` command no error is raised, but an error object
is returned in the format specified above (as a Lua table with an `err`
field). The script can pass the exact error to the user by returning
the error object returned by `redis.pcall()`.

Bandwidth and EVALSHA
---

The `EVAL` command forces you to send the script body again and again.
Redis does not need to recompile the script every time as it uses an internal
caching mechanism, however paying the cost of the additional bandwidth may
not be optimal in many contexts.

On the other hand, defining commands using a special command or via `redis.conf`
would be a problem for a few reasons:

* Different instances may have different versions of a command implementation.

* Deployment is hard if all the instances do not support a given command, especially in a distributed environment.

* Application code which uses commands defined server-side may cause confusion for other developers.

In order to avoid these problems while avoiding
the bandwidth penalty, Redis implements the `EVALSHA` command.

`EVALSHA` works exactly like `EVAL`, but instead of having a script as the first argument it has the SHA1 hash of a script. The behavior is the following:

* If the server still remembers a script with a matching SHA1 hash, the script is executed.

* If the server does not remember a script with this SHA1 hash, a special
error is returned telling the client to use `EVAL` instead.

Example:

    > set foo bar
    OK
    > eval "return redis.call('get','foo')" 0
    "bar"
    > evalsha 6b1bf486c81ceb7edf3c093f4c48582e38c0e791 0
    "bar"
    > evalsha ffffffffffffffffffffffffffffffffffffffff 0
    (error) `NOSCRIPT` No matching script. Please use `EVAL`.

The client library implementation can always optimistically send `EVALSHA` under
the hood even when the client actually calls `EVAL`, in the hope the script
was already seen by the server. If the `NOSCRIPT` error is returned `EVAL` will be used instead.

Passing keys and arguments as additional `EVAL` arguments is also
very useful in this context as the script string remains constant and can be
efficiently cached by Redis.

Script cache semantics
---

Executed scripts are guaranteed to be in the script cache **forever**.
This means that if an `EVAL` is performed against a Redis instance all the
subsequent `EVALSHA` calls will succeed.

The only way to flush the script cache is by explicitly calling the
SCRIPT FLUSH command, which will *completely flush* the scripts cache removing
all the scripts executed so far. This is usually
needed only when the instance is going to be instantiated for another
customer or application in a cloud environment.

The reason why scripts can be cached for long time is that it is unlikely
for a well written application to have enough different scripts to cause
memory problems. Every script is conceptually like the implementation of
a new command, and even a large application will likely have just a few
hundred of them. Even if the application is modified many times and
scripts will change, the memory used is negligible.

The fact that the user can count on Redis not removing scripts
is semantically a very good thing. For instance an application with
a persistent connection to Redis can be sure that if a script was
sent once it is still in memory, so EVALSHA can be used
against those scripts in a pipeline without the chance of an error
being generated due to an unknown script (we'll see this problem
in detail later).

The SCRIPT command
---

Redis offers a SCRIPT command that can be used in order to control
the scripting subsystem. SCRIPT currently accepts three different commands:

* SCRIPT FLUSH. This command is the only way to force Redis to flush the
scripts cache. It is most useful in a cloud environment where the same
instance can be reassigned to a different user. It is also useful for
testing client libraries' implementations of the scripting feature.

* SCRIPT EXISTS *sha1* *sha2* ... *shaN*. Given a list of SHA1 digests
as arguments this command returns an array of 1 or 0, where 1 means the
specific SHA1 is recognized as a script already present in the scripting
cache, while 0 means that a script with this SHA1 was never seen before
(or at least never seen after the latest SCRIPT FLUSH command).

* SCRIPT LOAD *script*. This command registers the specified script in
the Redis script cache. The command is useful in all the contexts where
we want to make sure that `EVALSHA` will not fail (for instance during a
pipeline or MULTI/EXEC operation), without the need to actually execute the
script.

* SCRIPT KILL. This command is the only way to interrupt a long-running
script that reaches the configured maximum execution time for scripts.
The SCRIPT KILL command can only be used with scripts that did not modify
the dataset during their execution (since stopping a read-only script does
not violate the scripting engine's guaranteed atomicity).
See the next sections for more information about long running scripts.

Scripts as pure functions
---

A very important part of scripting is writing scripts that are pure functions.
Scripts executed in a Redis instance are replicated on slaves by sending the
script -- not the resulting commands. The same happens for the Append Only File.
The reason is that sending a script to another Redis instance is much faster
than sending the multiple commands the script generates, so if the client is
sending many scripts to the master, converting the scripts into individual
commands for the slave / AOF would result in too much bandwidth for the
replication link or the Append Only File (and also too much CPU since
dispatching a command received via network is a lot more work for Redis
compared to dispatching a command invoked by Lua scripts).

The only drawback with this approach is that scripts are required to
have the following property:

* The script always evaluates the same Redis *write* commands with the
same arguments given the same input data set. Operations performed by
the script cannot depend on any hidden (non-explicit) information or state
that may change as script execution proceeds or between different executions of
the script, nor can it depend on any external input from I/O devices.

Things like using the system time, calling Redis random commands like
`RANDOMKEY`, or using Lua random number generator, could result into scripts
that will not always evaluate in the same way.

In order to enforce this behavior in scripts Redis does the following:

* Lua does not export commands to access the system time or other external state.

* Redis will block the script with an error if a script calls a
Redis command able to alter the data set **after** a Redis *random*
command like `RANDOMKEY`, `SRANDMEMBER`, `TIME`. This means that if a script is
read-only and does not modify the data set it is free to call those commands.
Note that a *random command* does not necessarily mean a command that
uses random numbers: any non-deterministic command is considered a random
command (the best example in this regard is the `TIME` command).

* Redis commands that may return elements in random order, like `SMEMBERS`
(because Redis Sets are *unordered*) have a different behavior when called from Lua, and undergo a silent lexicographical sorting filter before returning data to Lua scripts. So `redis.call("smembers",KEYS[1])` will always return the Set elements in the same order, while the same command invoked from normal clients may return different results even if the key contains exactly the same elements.

* Lua pseudo random number generation functions `math.random` and
`math.randomseed` are modified in order to always have the same seed every
time a new script is executed. This means that calling `math.random` will
always generate the same sequence of numbers every time a script is
executed if `math.randomseed` is not used.

However the user is still able to write commands with random behavior
using the following simple trick. Imagine I want to write a Redis
script that will populate a list with N random integers.

I can start with this small Ruby program:

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
    puts r.eval(RandomPushScript,1,:mylist,10)

Every time this script executed the resulting list will have exactly the
following elements:

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
    10) "0.17082803611217"

In order to make it a pure function, but still be sure that every
invocation of the script will result in different random elements, we can
simply add an additional argument to the script that will be used in order to
seed the Lua pseudo-random number generator. The new script is as follows:

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

What we are doing here is sending the seed of the PRNG as one of the
arguments. This way the script output will be the same given the same
arguments, but we are changing one of the arguments in every invocation,
generating the random seed client-side. The seed will be propagated as
one of the arguments both in the replication link and in the Append Only
File, guaranteeing that the same changes will be generated when the AOF
is reloaded or when the slave processes the script.

Note: an important part of this behavior is that the PRNG that Redis implements
as `math.random` and `math.randomseed` is guaranteed to have the same output
regardless of the architecture of the system running Redis. 32-bit, 64-bit,
big-endian and little-endian systems will all produce the same output.

Global variables protection
---

Redis scripts are not allowed to create global variables, in order to avoid
leaking data into the Lua state. If a script needs to maintain state between
calls (a pretty uncommon need) it should use Redis keys instead.

When global variable access is attempted the script is terminated and EVAL returns with an error:

    redis 127.0.0.1:6379> eval 'a=10' 0
    (error) ERR Error running script (call to f_933044db579a2f8fd45d8065f04a8d0249383e57): user_script:1: Script attempted to create global variable 'a' 

Accessing a *non existing* global variable generates a similar error.

Using Lua debugging functionality or other approaches like altering the meta
table used to implement global protections in order to circumvent globals
protection is not hard. However it is difficult to do it accidentally.
If the user messes with the Lua global state, the consistency of AOF and
replication is not guaranteed: don't do it.

Note for Lua newbies: in order to avoid using global variables in your scripts simply declare every variable you are going to use using the *local* keyword.

Available libraries
---

The Redis Lua interpreter loads the following Lua libraries:

* base lib.
* table lib.
* string lib.
* math lib.
* debug lib.
* cjson lib.
* cmsgpack lib.

Every Redis instance is *guaranteed* to have all the above libraries so you
can be sure that the environment for your Redis scripts is always the same.

The CJSON library provides extremely fast JSON maniplation within Lua.
All the other libraries are standard Lua libraries.

Emitting Redis logs from scripts
---

It is possible to write to the Redis log file from Lua scripts using the
`redis.log` function.

    redis.log(loglevel,message)

loglevel is one of:

* `redis.LOG_DEBUG`
* `redis.LOG_VERBOSE`
* `redis.LOG_NOTICE`
* `redis.LOG_WARNING`

They correspond directly to the normal Redis log levels. Only logs emitted by
scripting using a log level that is equal or greater than the currently configured
Redis instance log level will be emitted.

The `message` argument is simply a string. Example:

    redis.log(redis.LOG_WARNING,"Something is wrong with this script.")

Will generate the following:

    [32343] 22 Mar 15:21:39 # Something is wrong with this script.

Sandbox and maximum execution time
---

Scripts should never try to access the external system, like the file system
or any other system call. A script should only operate on Redis data and passed
arguments.

Scripts are also subject to a maximum execution time (five seconds by default).
This default timeout is huge since a script should usually run in under a
millisecond. The limit is mostly to handle accidental infinite loops created
during development.

It is possible to modify the maximum time a script can be executed
with millisecond precision, either via `redis.conf` or using the
CONFIG GET / CONFIG SET command. The configuration parameter
affecting max execution time is called `lua-time-limit`.

When a script reaches the timeout it is not automatically terminated by
Redis since this violates the contract Redis has with the scripting engine
to ensure that scripts are atomic. Interrupting a script means potentially
leaving the dataset with half-written data.
For this reasons when a script executes for more than the specified time
the following happens:

* Redis logs that a script is running too long.
* It starts accepting commands again from other clients, but will reply with a BUSY error to all the clients sending normal commands. The only allowed commands in this status are `SCRIPT KILL` and `SHUTDOWN NOSAVE`.
* It is possible to terminate a script that executes only read-only commands using the `SCRIPT KILL` command. This does not violate the scripting semantic as no data was yet written to the dataset by the script.
* If the script already called write commands the only allowed command becomes `SHUTDOWN NOSAVE` that stops the server without saving the current data set on disk (basically the server is aborted).

EVALSHA in the context of pipelining
---

Care should be taken when executing `EVALSHA` in the context of a pipelined
request, since even in a pipeline the order of execution of commands must
be guaranteed. If `EVALSHA` will return a `NOSCRIPT` error the command can not
be reissued later otherwise the order of execution is violated.

The client library implementation should take one of the following
approaches:

* Always use plain `EVAL` when in the context of a pipeline.

* Accumulate all the commands to send into the pipeline, then check for
`EVAL` commands and use the `SCRIPT EXISTS` command to check if all the
scripts are already defined. If not, add `SCRIPT LOAD` commands on top of
the pipeline as required, and use `EVALSHA` for all the `EVAL` calls.
