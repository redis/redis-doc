Load a library to Redis.

The command's first argument, _enginie-name_, is the name of the execution engine for the library.
Presently, Redis only supports the _Lua_ engine.

The _library-name_ argument is the unique name of the library.
Following it is the source code that implements the library.
For the Lua engine, the implementation should declare one or more entry points to the library with the [`redis.register_function()` API](/topics/lua-api#redis.register_function()).
Once loaded, you can call the functions in the library with the `FCALL` (or `FCALL_RO` when applicable) command.

When attempting to load a library with a name that already exists, the Redis server returns an error.
The `REPLACE` modifier changes this behavior, and overwrites the existing library with the new contents.

You can also use the optional `DESCRIPTION` argument to attach a description to the library.

The command will return an error in the following circumstances:

* An invalid _engine-name_ was provided.
* The library's name already exists without the `REPLACE` modifier.
* A function in the library is created with a name that already exists in another library (even when `REPLACE` is specified).
* The engine failed in creating library's functions (due to a compilation error, for example).
* No functions were declared by the library.

For more information please refer to [Introduction to Redis Functions](/topics/function)

@return

@simple-string-reply

@examples

The following example will create a library named _mylib_ with a single function, _myfunc_, that returns the first argument it gets.

```
redis> FUNCTION LOAD Lua mylib "redis.register_function('myfunc', function(keys, args) return args[1] end)"
OK
redis> FCALL myfunc 0 hello
"hello"
```
