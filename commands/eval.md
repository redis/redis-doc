Invoke a Lua script on the server side.

The second argument of is the number of keys,
follow by all the keys access by the function.
All the additional arguments should not represent key names.

On Lua engine, keys are stored as a Lua table and given as global variable named `!KEYS`.
The rest of the values also stored as a Lua table and given as a global variable named `!ARGV`.

For more information about `EVAL` scripts please refer to [Introduction to Eval Scripts](/topics/evalintro)

@examples

The following example will run a script that returns the first argument it gets.

```
> eval "return args[1]" 0 hello
"hello"
```
