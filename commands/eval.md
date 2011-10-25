@complexity

Looking up the script both with EVAL or EVALSHA is an O(1) business. The additional complexity is up to the script you execute.

Waring
---

Redis scripting support is currently a work in progress. This feature will be shipped as stable with the release of Redis 2.6. The information in this document reflects what is currently implemented, but it is possible that changes will be made before the release of the stable version.

Introduction to EVAL
---

EVAL and EVALSHA are used to evaluate scripts using the Lua interpreter
built into Redis starting from version 2.6.0.

The first argument of EVAL itself is a Lua script. The script does not need
to define a Lua function, it is just a Lua program that will run in the context
of the Redis server.

The second argument of EVAL is the number of arguments that follows
(starting from the third argument) that represent Redis key names.
This arguments can be accessed by Lua using the KEYS global variable in
the form of an one-based array (so KEY[1], KEY[2], ...).

All the additional arguments that should not represent key names can
be accessed by Lua using the ARGV global variable, very similarly to
what happens with keys (so ARGV[1], ARGV[2], ...).

The following example can clarify what stated above:

    > eval "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}" 2 key1 key2 first second
    1) "key1"
    2) "key2"
    3) "first"
    4) "second"

Note: as you can see Lua arrays are returend as Redis multi bulk replies, that is a Redis return type that your client library will likely convert into an Array in your programming language.

It is possible to call Redis program from a Lua script using two different
Lua functions:

* redis.call()
* redis.pcall()

redis.call() is similar to redis.pcall(), the only difference is that if a
Redis command call will result into an error, redis.call() will raise a
Lua error that in turn will make EVAL to fail, while redis.pcall will trap
the error returning a Lua table representing the error.

The arguments of the redis.call() and redis.pcall() functions are simply
all the arguments of a well formed Redis command:

    > eval "return redis.call('set','foo','bar')" 0
    OK

The above script works and will set the key `foo` to the string "bar".
However it violates the EVAL command semantics as all the keys that the
script uses should be passed using the KEYS array, in the following way:

    > eval "return redis.call('set',KEYS[1],'bar')" 1 foo
    OK

The reason for passing keys in the proper way is that, before of EVAL all
the Redis commands could be analyzed before execution in order to
enstablish what are the keys the command will operate on.

In order for this to be true for EVAL also keys must be explicit.
This is useful in many ways, but especially in order to make sure Redis Cluster
is able to forward your request to the appropriate cluster node (Redis
Cluster is a work in progress, but the scripting feature was designed
in order to play well with it).

Lua scripts can return a value that is converted from Lua to the Redis protocol
using a set of conversion rules.

Conversion between Lua and Redis data types
---

Redis return values are converted into Lua data types when Lua calls a
Redis command using call() or pcall(). Similarly Lua data types are
converted into Redis data types when a script returns some value, that
we need to use as the EVAL reply.

This conversion between data types is designed in a way that if
a Redis type is converted into a Lua type, and then the result is converted
back into a Redis type, the result is the same as of the initial value.

In other words there is a one to one conversion between Lua and Redis types.
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

There is an additional Lua to Redis conversion that has no corrisponding
Redis to Lua conversion:

 * Lua boolean true -> Redis integer reply with value of 1.

The followings are a few conversion examples:

    > eval "return 10" 0
    (integer) 10

    > eval "return {1,2,{3,'Hello World!'}}" 0
    1) (integer) 1
    2) (integer) 2
    3) 1) (integer) 3
       2) "Hello World!"

    > eval "return redis.call('get','foo')" 0
    "bar"

The last example shows how it is possible to directly return from Lua
the return value of redis.call() and redis.pcall() with the result of
returning exactly what the called command would return if called directly.

Atomicity of scripts
---

Redis uses the same Lua interpreter to run all the commands. Also Redis
guarantees that a script is executed in an atomic way: nor other scripts
or other Redis commands will be executed while a script is being executed.
This semantics is very similar to the one of `MULTI` / `EXEC`.

However this also means that executing slow scripts is not a good idea.
It is not hard to create fast scripts, as the script overhead is very low,
but if you are going to use slow scripts you should be aware that while the
script is running no other client can execute commands since the server
is busy.

Error handling
---

As already stated calls to redis.call() resulting into a Redis command error
will stop the execution of the script and will return that error back, in a
way that makes it obvious the error was generated by a script:

    > del foo
    (integer) 1
    > lpush foo a
    (integer) 1
    > eval "return redis.call('get','foo')" 0
    (error) ERR Error running script (call to f_6b1bf486c81ceb7edf3c093f4c48582e38c0e791): ERR Operation against a key holding the wrong kind of value 

Using the redis.pcall() command no error is raised, but an error object
is returned in the format specified above (as a Lua table with an `err`
field). The user can later return this error to the user just returning the
error object returned by redis.pcall().

Bandwidth and EVALSHA
---

The EVAL command forces you to send the script body again and again, even if
it does not need to recompile the script every time as it uses an internal
caching mechanism. However paying the cost of the additional bandwidth may
not be optimal in all the contexts.

On the other hand defining commands using a special command or via redis.conf
would be a problem for a few reasons:

* Different instances may have different versions of a command implementation.
* Deployment is hard if there is to make sure all the instances contain a given command, especially in a distributed environment.
* Reading an application code the full semantic could not be clear since the app would call commands defined server side.

In order to avoid the above three problems and at the same time don't incur
in the bandwidth penalty Redis implements the EVALSHA command.

EVALSHA works exactly as EVAL, but instead of having a script as first argument
it has the SHA1 sum of a script. The behavior is the following:

* If the server still remembers a script whose SHA1 sum was the one specified, the script is executed.
* If the server does not remember a script with this SHA1 sum, a special error is returned that will tell the client to use EVAL instead.

Example:

    > set foo bar
    OK
    > eval "return redis.call('get','foo')" 0
    "bar"
    > evalsha 6b1bf486c81ceb7edf3c093f4c48582e38c0e791 0
    "bar"
    > evalsha ffffffffffffffffffffffffffffffffffffffff 0
    (error) NOSCRIPT No matching script. Please use EVAL.

The client library implementation can always optimistically send EVALSHA under
the hoods even when the client actually called EVAL, in the hope the script
was already seen by the server. If the NOSCRIPT error is returned EVAL will be
used instead. Passing keys and arguments as EVAL additional arguments is also
very useful in this context as the script string remains constant and can be
efficiently cached by Redis.

Script cache semantics
---

Executed scripts are guaranteed to be in the script cache forever.
This means that if an EVAL is performed against a Redis instance all the
subsequent EVALSHA calls will succeed.

The only way to flush the script cache is by explicitly calling the
SCRIPT FLUSH command, that will flush the scripts cache. This is usually
needed only when the instance is going to be instantiated for another
customer in a cloud environment.

The reason why scripts can be cached for long time is that it is unlikely
for a well written application to have so many different scripts to create
memory problems. Every script is conceptually like the implementation of
a new command, and even a large application will likely have just a few
hundreds of that. Even if the application is modified many times and
scripts will change, still the memory used is negligible.

The fact that the user can count on Redis not removing scripts
is semantically a very good thing. For instance an application taking
a persistent connection to Redis can stay sure that if a script was
sent once it is still in memory, thus for instance can use EVALSHA
against those scripts in a pipeline without the change that an error
will be generated since the script is not knonw (we'll see this problem
in its details later).

The SCRIPT command
---

Redis offers a SCRIPT command that can be used in order to control
the scripting subsystem. SCRIPT currently accepts three different commands:

* SCRIPT FLUSH. This command is the only way to force Redis to flush the scripts cache. It is mostly useful in a cloud environment where the same instance can be reassigned to a different user. It is also useful for testing client libraries implementations of the scripting feature.
* SCRIPT EXISTS *sha1* *sha2* ... *shaN*. Given a list of SHA1 digests as arguments this command returns an array of 1 or 0, where 1 means the specific SHA1 is recognized as a script already present in the scripting cache, while 0 means that a script with this SHA1 was never seen before (or at least never seen after the latest SCRIPT FLUSH command).
* SCRIPT LOAD *script*. This command registers the specified script in the Redis script cache. The command is useful in all the contexts where we want to make sure that EVALSHA will not fail (for instance during a pipeline or MULTI/EXEC operation).

Scripts as pure functions
---

A very important part of scripting is writing scripts that are pure functions.
Scripts executed in a Redis instance are replicated on slaves sending the
same script, instead of the resulting commands. The same happens for the
Append Only File. The reason is that scripts are much faster than sending
commands one after the other to a Redis instance, so if the client is
taking the master very busy sending scripts, turing this scripts into single
commands for the slave / AOF would result in too much load for the replication
link or the Append Only File.

The only drawback with this approach is that scripts are required to
have the following property:

* The script always evaluates the same Redis *write* commands with the same arguments given the same input data set. Operations perfomed by the script cannot depend on any hidden information or state that may change as script execution proceeds or between different executions of the script, nor can it depend on any external input from I/O devices.

Things like using the system time, calling Redis random commands like
RANDOMKEY, or using Lua random number generator, could result into scripts
that will not evaluate always in the same way.

In order to enforce this behavior in scripts Redis does the following:

* Lua does not export commands to access the system time or other external state.
* Redis will block the script with an error if a script will call a Redis command able to alter the data set **after** a Redis random command like RANDOMKEY or SRANDMEMBER. This means that if a script is read only and does not modify the data set it is free to call those commands.
* Lua pseudo random number generation functions math.random and math.randomseed are modified in order to always have the same seed every time a new script is executed. This means that calling math.random will always generate the same sequence of numbers every time a script is executed if math.randomseed is not used.

However the user is still able to write commands with random behaviors using the following simple trick. For example I want to write a Redis script that will populate a list with N random integers.

I can start writing the following script, using a small Ruby program:

    require 'rubygems'
    require 'redis'

    r = Redis.new

    RandomPushScript = <<EOF
        local i = tonumber(ARGV[1])
        while (i > 0) do
            res = redis.call('lpush',KEYS[1],math.random())
            i = i-1
        end
        return res
    EOF

    r.del(:mylist)
    puts r.eval(RandomPushScript,1,:mylist,10)

Every time this script executed the resulting list will have exactly the following elements:

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

In order to make it a pure function, but still making sure that every
invocation of the script will result in a different random elements, we can
simply add an additional argument to the script, that will be used in order to
seed the Lua PRNG. The new script will be like the following:

    RandomPushScript = <<EOF
        local i = tonumber(ARGV[1])
        math.randomseed(tonumber(ARGV[2]))
        while (i > 0) do
            res = redis.call('lpush',KEYS[1],math.random())
            i = i-1
        end
        return res
    EOF

    r.del(:mylist)
    puts r.eval(RandomPushScript,1,:mylist,10,rand(2**32))

What we are doing here is to send the seed of the PRNG as one of the arguments. This way the script output will be the same given the same arguments, but we
are changing one of the argument at every invocation, generating the random
seed client side. The seed will be propagated as one of the arguments both
in the replication link and in the Append Only File, guaranteeing that the
same changes will be generated when the AOF is reloaded or when the slave
will process the script.

Note: an important part of this behavior is that the PRNG that Redis implements
as math.random and math.randomseed is guaranteed to have the same output
regardless of the architecture of the system running Redis. 32 or 64 bit systems
like big or little endian systems will still produce the same output.

Available libraries
---

The Redis Lua interpreter loads the following Lua libraries:

* Base lib.
* Table lib.
* String lib.
* Math lib.
* Debug lib.
* CJSON lib.

Every Redis instance is *guaranteed* to have all the above libraries so you
can be sure that the environment for your Redis scripts is always the same.

The CJSON library allows to manipulate JSON data in a very fast way from Lua.
All the other librareis are standard Lua libraries.

Sandbox and maximum execution time
---

Scripts should never try to access the external system, like the fileystem,
nor calling any other system call. A script should just do its work operating
on Redis data, starting form Redis data.

Scripts also are subject to a maxium execution time of five seconds.
This default timeout is huge since a script should run usually in a sub
millisecond amount of time. The limit is mostly needed in order to avoid
problems when developing scripts that may loop forever for a programming
error.

It is possible to modify the maximum time a script can be executed
with milliseconds precision, either via redis.conf or using the
CONFIG GET / CONFIG SET command. The configuration parameter
affecting max execution time is called `lua-time-limit`.

EVALSHA in the context of pipelining
---

Care should be taken when executing EVALSHA in the context of a pipelined
request, since even in a pipeline the order of executin of commands must
be guaranteed. If EVALSHA will return a NOSCRIPT error the command can not
be reissued later otherwise the order of execution is violated.

The client library implementation should take one of the following
approaches:

* Always use plain EVAL when in the context of a pipeline.
* Accumulate all the commands to send into the pipeline, then check for EVAL commands and use the SCRIPT EXISTS command to check if all the scrits are already defined. If not add SCRIPT LOAD commands on top of the pipeline as requierd, and use EVALSHA for all the EVAL calls.

