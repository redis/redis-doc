Invoke a function previously uploaded using `FUNCTION LOAD`.

The second argument of `FCALL`/`FCALL_RO` is the number of keys follow by
all the keys access by the function. All the additional arguments
should not represent key names.

On Lua engine, keys are stored as a Lua table and given as the first
argument to the called function. The rest of the values also stored
as a Lua table and given as the second argument to the called function.

For more information about functions please refer to [Introduction to Redis Functions](/topics/function)

@examples

The following example will create a library, `test`, with a single function, `f1`, that returns the first argument it gets.

```
> function load lua test "redis.register_function('f1', function(keys, args) return args[1] end)"
OK
> fcall f1 0 hello
"hello"
```