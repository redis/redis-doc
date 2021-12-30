Return information about the function currently running.

The returned information:

* Function name
* Command used to invoke the function
* Duration in MS that the function is running

If no function is running, returns nil.
In addition, returns a list of available engines.

This command can be used see detect a long running function and decide
whether or not to kill it using `FUNCTION KILL`.

For more information about functions please refer to [Introduction to Redis Functions](/topics/function)

@examples
The following example detects a long running script.

```
> function stats
1) "running_script"
2) 1) "name"
   2) "f5"
   3) "command"
   4) 1) "fcall"
      2) "f5"
      3) "0"
   5) "duration_ms"
   6) (integer) 18935
3) "engines"
4) 1) "LUA"
> function kill
OK
> function stats
1) "running_script"
2) (nil)
3) "engines"
4) 1) "LUA"
```