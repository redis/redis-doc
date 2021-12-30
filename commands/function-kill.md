Kill the current running function.

It is only possible to kill a function that did not yet modified the data
(killing a function that already modified the data will break function atomicity and disallowed)

For more information about functions please refer to [Introduction to Redis Functions](/topics/function)

@return

@simple-string-reply

@examples
The following kills a long running function.

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