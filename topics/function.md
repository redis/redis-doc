# Introduction to Redis Functions
 
Redis Functions is a new scripting approach first introduced on Redis 7.
Before Redis 7 the only scripting approach that was available to the user
was `EVAL`. `EVAL` allows users to send a Lua script which was invoked
by Redis. One of the common use case that was covered is to provide a reacher
API than the API provided by Redis commands, users could send a script that
updates multiple keys together, keep keys in sync (for example, maintains a
list of all users such that each user is a key by itself). And in general,
provides a schema over Redis data structures.
 
The problem with `EVAL` was that the user needed to send the script
over and over each time, this came with network and compilation overhead.
To solve this, `EVALSHA` was introduced. With `EVALSHA`, users can invoke a script
by sending the script sha calculation (previously uploaded by `SCRIPT LOAD`).
Though solving the compilation and network overhead, `EVALSHA` was still not
a complete solution to the schema use-case. Scripts that was uploaded with
`SCRIPT LOAD` could, by definition, be lost at any time, and it was the client
responsibility to re-upload them if they are missing. The assumption is that the
scripts is part of the client application that runs on the server and its not
Redis' responsibility to maintain them. Those properties causes several issues:

1. Users need to maintain the script on all clients applications. Which means
  that on changes/fixes all clients application required update.
2. `EVALSHA` inside multi exec is inherently risky (in case the script is missing).
3. Meaningless SHAs are harder to identify and debug, e.g. in a MONITOR session
4. `EVAL` inadvertently promotes the wrong pattern of rendering scripts on the client
  side instead of using KEYS and ARGV.

Another issue with `EVAL` was the inability to share code between scripts.
If one script needs to share the functionality of another script, it needs to duplicate
the code. Of course, this can be done automatically by preprocessing the script, but it
was only possible on the client side which made script development difficult.
 
All those issues led to the definition of Redis Functions. Redis functions are an
evolution of Redis' scripts. They provide the same core functionality, but they are
guaranteed to be persistent and replicated, so the user does not need to worry about
them being missing. Conceptually, **if current scripts are treated as client code that
runs on the server, then functions are extensions to the server logic that can be
implemented by the user**. Function are also named and invoke by their name so its easier
to identify and monitor.
 
Functions design also attempts to decouple the language in which functions are
written. Lua is simple and easy to learn, but for many users it’s still an obstacle.
The design and commands definitions makes no assumptions about the programming
language in which functions are implemented. Instead, we define an engine component
that is responsible for executing functions. Engines can execute functions in any
language as long as they respect certain rules like the ability to kill a function's
execution. Redis 7 comes with one (and only) engine, the Lua engine. More engines
are planned for the future. **All the script capabilities describe on `EVAL` are also
apply for Lua functions** (with one exception, server side debugging is not supported).

In order to solve the code sharing issue and make user life easier, Redis Function is
not a stand along script, it can be given to Redis as batch of multiple functions. Functions
that were created together can safely share code between each other without worrying about
compatibility issues and versioning. We call this group of functions that was uploaded
together a library. Libraries are immutable so it is not possible to delete or update a
single function inside a library, the entire library needs to be updated/deleted together.

Functions purpose is to solve the schema usecase (as describe above). As such, the created
functions are saved along side with the data. functions are replicated to replicas and AOF,
and are saved as part of the RDB file. **Losing data means to also lose the functions!!!**
so running without persistency or replication require special treatment for function that
will be discussed later on.

As with the current scripting approach, functions are atomic. During function execution,
Redis is blocked and doesn't accept any commands. This implies that **functions are intended
for short execution times, and not long running operations**, just like Lua scripts.

## Getting Started

The following taturial will explain the basics of Redis Functions and how to use them.
The taturial uses the Lua engine for code examples.

Library code is loaded into Redis using the `FUNCTION LOAD` command. When an engine receives
the code given on `FUNCTION LOAD` command it will be able to register one or more functions.
Each engine can decide how to expose the registration capability to the user, some engines
will need to run parts of the code in order to know which functions it creates while others
will only need to introspect the code. Spacifically the Lua function will run the code,
it is then the user responsibility to register functions into the library using
`redis.register_function` API, running the following script register a simple function
called `hello` that simply returns `hello`:

```
redis.register_function(
  'hello',
  function() return 'hello' end
)
```

the first argument to `redis.register_function` is the function name, and the second argument
is the function callback. We can load the library with the following `FUNCTION LOAD` command:

```
> function load lua lib "redis.register_function('hello', function() return 'hello' end)"
OK
```

And we can invoke the function using `FCALL` command:

```
> fcall hello 0
hello
```

Notice that `FCALL` recieves an additional argument `0`, this argument represent the number of keys
we pass to our function (follow by all the keys). In this simple example our function recieves no
keys nor values so we simple give `0`. We will disscuss later how to retrieve the keys and arguments
inside our function.

Now lets implement something more complicated, assuming we want to give an API that extend the `HSET`
command and add a field to the hash that represent the last time the hash was changed. We can use
the `TIME` command to get the current time (in second) and add it to the hash under field called
`_last_modified`. But how do we get the fields and the value we want to update inside the hash?
As mentioned above, the `FCALL` command can get multiple keys and values as part of the command arguments.
In our case, the key will be the hash key name and the arguments will be a list of fields and values to
update. On Lua, it is possible to get the keys and the arguments as parameter to our function. The first
parameter is a Lua table contains all the keys and the second parameter is a Lua tables contains all the
additional arguments. The code will look like this:

```
redis.register_function(
  'my_hset',
  function(keys, args)
    # get the time
    local time = redis.call('time')[1]
    return redis.call('hset', keys[1], '_last_modified', time, unpack(args))
  end
)
```

In our example, we first read the current time using `redis.call('time')[1]` and save it to
a local variable, then we call `HSET` command on the key given on the `FCALL` alongside 
the arguments and the current time. Again we can load the library using `FUNCTION LOAD` command:

```
> function load lua my_hash_api "redis.register_function('my_hset', function(keys, args) local time = redis.call('time')[1]; return redis.call('hset', keys[1], '_last_modified', time, unpack(args)) end)"
OK
```

And now we can use our new function and set hash with `_last_modified` field:

```
> FCALL my_hset 1 key1 foo1 bar1 foo2 bar2
(integer) 3
> hgetall key1
1) "_last_modified"
2) "1640772721"
3) "foo1"
4) "bar1"
5) "foo2"
6) "bar2"
```

Notice that new, instead of `0` we give `1` as the first arguement after the function name.
This means that we are passing a single key (`key1`) to our function.

Lets take our example another step forward, assuming we also want to implement additional 2 API's:

1. `MY_HGETALL`, will give the same functionality as `HGETALL` but will not return the `_last_modified` field.
2. `MY_HLASTMODIFIED`, Will return the last modified value for a hash.

The code will now will look like this:

```
redis.register_function(
  'my_hset',
  function(keys, args)
    # get the time
    local time = redis.call('time')[1]
    return redis.call('hset', keys[1], '_last_modified', time, unpack(args))
  end
)

redis.register_function(
  'my_hgetall',
  function(keys, args)
    redis.setresp(3)
    local res = redis.call('hgetall', keys[1])
    res['map']['_last_modified'] = nil
    return res
  end
)

redis.register_function(
  'my_hlastmodified',
  function(keys, args)
    return redis.call('hget', keys[1], '_last_modified')
  end
)
```

An important thing to notice is that `my_hgetall` function uses `redis.setresp(3)` to indicate
that it wants the reply in [resp3](https://github.com/antirez/RESP3/blob/master/spec.md) format.
This allows us to later pop the `_last_modified` field out of the returned result. For more imforamtion
about Lua API refer to [Redis Lua API](/topics/lua) spacifications.

We can load this new library using `FUNCTION LOAD` command but this time we will use the
`REPLACE` argument indicate we want to replace the already existing library with the same
name. We also give a library description to explain what the library does.


```
> function load lua my_hash_api REPLACE DESCRIPTION "hash api enhancements" "redis.register_function('my_hset', function(keys, args) local time = redis.call('time')[1]; return redis.call('hset', keys[1], '_last_modified', time, unpack(args)) end); redis.register_function('my_hgetall', function(keys, args) redis.setresp(3); local res = redis.call('hgetall', keys[1]); res['map']['_last_modified'] = nil;return res end); redis.register_function('my_hlastmodified', function(keys, args) return redis.call('hget', keys[1], '_last_modified') end)"
OK
```

And we can run our new functions, again, using `FCALL`

```
> fcall my_hgetall 1 key1
1) "foo1"
2) "bar1"
3) "foo2"
4) "bar2"
> fcall my_hlastmodified 1 key1
"1640772721"
```

We can get information about our library using `FUNCTION LIST` command:

```
> function list
1) 1) "library_name"
   2) "my_hash_api"
   3) "engine"
   4) "LUA"
   5) "description"
   6) "hash api enhancements"
   7) "functions"
   8) 1) 1) "name"
         2) "my_hset"
         3) "description"
         4) (nil)
      2) 1) "name"
         2) "my_hgetall"
         3) "description"
         4) (nil)
      3) 1) "name"
         2) "my_hlastmodified"
         3) "description"
         4) (nil)
```

You can see that it is easy to update our library with new capabilities.

Another important asspect of libraries is code sharing. We can introduce a function which is not
a Redis function by itself, but it can be used internally by all Redis functions on the same library.
Let create, for example, a log function that will be used to log errors inside our library.

```
local function log_error(msg)
  redis.log('my_hash: ' + msg)
end
```

Now lets use our `log_error` functions to log usage errors, the full code will look like this:

```
local function log_error(msg)
  redis.log(redis.LOG_WARNING, 'my_hash: ' .. msg)
end

redis.register_function(
  'my_hset',
  function(keys, args)
    if table.getn(keys) == 0 then
      log_error('hash key was not given')
      return {err = 'hash key was not given'}
    end
    # get the time
    local time = redis.call('time')[1]
    return redis.call('hset', keys[1], '_last_modified', time, unpack(args))
  end
)

redis.register_function(
  'my_hgetall',
  function(keys, args)
    if table.getn(keys) == 0 then
      log_error('hash key was not given')
      return {err = 'hash key was not given'}
    end
    redis.setresp(3)
    local res = redis.call('hgetall', keys[1])
    res['map']['_last_modified'] = nil
    return res
  end
)

redis.register_function(
  'my_hlastmodified',
  function(keys, args)
    if table.getn(keys) == 0 then
      log_error('hash key was not given')
      return {err = 'hash key was not given'}
    end
    return redis.call('hget', keys[1], '_last_modified')
  end
)
```

Notice that in case of an error we return a Lua table with a single `err` key, this will indicate Redis to
return the message to the user as an error. For more imforamtion about Lua API refer to 
[Redis Lua API](/topics/lua) spacifications.

Let's load the library with `FUNCTION LOAD`:

```
> function load lua my_hash_api REPLACE DESCRIPTION "hash api enhancements" "local function log_error(msg) redis.log(redis.LOG_WARNING, 'my_hash: ' .. msg) end; redis.register_function('my_hset', function(keys, args) if table.getn(keys) == 0 then log_error('hash key was not given'); return {err = 'hash key was not given'} end local time = redis.call('time')[1]; return redis.call('hset', keys[1], '_last_modified', time, unpack(args)) end); redis.register_function('my_hgetall', function(keys, args) if table.getn(keys) == 0 then log_error('hash key was not given'); return {err = 'hash key was not given'} end; redis.setresp(3); local res = redis.call('hgetall', keys[1]); res['map']['_last_modified'] = nil; return res; end); redis.register_function('my_hlastmodified', function(keys, args) if table.getn(keys) == 0 then log_error('hash key was not given'); return {err = 'hash key was not given'} end; return redis.call('hget', keys[1], '_last_modified') end)"
OK
```

Running it now without a key will result in the following error and log message will be printed to Redis log file:

```
> fcall my_hlastmodified 0
(error) hash key was not given
```

Redis log file:

```
813606:M 29 Dec 2021 13:38:35.942 # my_hash: hash key was not given
```

## Whats Next?

### Related topics for further reading

* [Redis Programability](/topics/programability)
* [Redis Lua API](/topics/lua)
* [Redis Eval Scripts](/topics/evalintro)

### Redis Functions Command list

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