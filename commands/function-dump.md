Returns a serialized payload representing the current libraries.
The serialized payload can later be restored using `FUNCTION RESTORE` command.

For more information about functions please refer to [Introduction to Redis Functions](/topics/function)

@return

@bulk-string-reply: the serialized payload

@examples

The following example dump the current libraries using `FUNCTION DUMP`, then flushes all the libraries
using `FUNCTION FLUSH`, and then restore the original functions using `FUNCTION RESTORE`.

```
> FUNCTION DUMP
"\xf6\x05test3\x03LUA\x00@Fredis.register_function('f5', function(keys, args) while 1 do end end)\n\x00wY\xbb \xec\x0f\x91i"
> FUNCTION FLUSH
OK
> FUNCTION RESTORE "\xf6\x05test3\x03LUA\x00@Fredis.register_function('f5', function(keys, args) while 1 do end end)\n\x00wY\xbb \xec\x0f\x91i"
OK
127.0.0.1:6379> FUNCTION LIST
1) 1) "library_name"
   2) "test3"
   3) "engine"
   4) "LUA"
   5) "description"
   6) (nil)
   7) "functions"
   8) 1) 1) "name"
         2) "f5"
         3) "description"
         4) (nil)
```