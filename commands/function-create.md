Load a library into Redis.

The library `code` is given to the specified `engine` for compiling and
processing, this processing should result in creating one or more functions
that can be later invoked using `FCALL` command. On Lua engine, it is possible
to create function using `redis.register_function` API (see example bellow).

If the given `library-name` already exists, error is returns unless the `REPLACE`
argument is given, in this case, replace the old library with the
new one. Library description can also be given using the `DESCRIPTION`
argument.

An error will occured at the following cases:

* Given `engine` does not exists
* Library name already exists and `REPLACE` was not used
* Function name already exists on another library (notice that this may happened even if `REPLACE` was used)
* The engine failed to create functions from the given `code` (usually this happends because of compilation error).
* The engine did not created any functions from the give `code`

For more information about functions please refer to [Introduction to Redis Functions](/topics/function)

@return

@simple-string-reply

@examples

The following example will create a library, `test`, using the Lua engine. The library have a single function, `f1`, that simply returns `hello`.

```
> function load lua test "redis.register_function('f1', function(keys, args) return 'hello' end)"
OK
> fcall f1 0
"hello"
```
