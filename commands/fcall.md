Invoke a function.

Functions are loaded to the server with the `FUNCTION LOAD` command.
The first argument is the name of a loaded function.

The second argument is the number of input key name arguments, followed by all the keys accessed by the function.
In Lua, these names of input keys are available to the function as a table that is the callback's first arugment.

**Important:**
to ensure the correct execution of functions, both in standalone and clustered deployments, all names of keys that a function accesses must be explicitly provided as input key arguments.
The script **should only** access keys whose names are given as input arguments.
Scripts **should never** access keys with programmatically-generated names or based on the contents of data structures stored in the database.

Any additional input arguments **should not** represent names of keys.
These are regular arguments, and are passed in a Lua table as the callback's second argument.

For more information please refer to thTe [Redis Programmability](/topics/programmability) and [Introduction to Redis Functions](/topics/functions-intro) pages.

@examples

The following example will create a library named _mylib_ with a single function, _myfunc_, that returns the first argument it gets.

```
redis> FUNCTION LOAD Lua mylib "redis.register_function('myfunc', function(keys, args) return args[1] end)"
OK
redis> FCALL myfunc 0 hello
"hello"
```
