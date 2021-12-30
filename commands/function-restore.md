Restore the libraries represented by the given payload,
it is possible to give a restore policy to control how to handle existing libraries (default APPEND):

* FLUSH: delete all existing libraries.
* APPEND: appends the restored libraries to the existing libraries. On collision, abort.
* REPLACE: appends the restored libraries to the existing libraries.
On collision, replace the old libraries with the new libraries
(notice that even on this option there is a chance of failure in case of functions name collision with another library).

For more information about functions please refer to [Introduction to Redis Functions](/topics/function)

@return

@simple-string-reply

@examples
```
> FUNCTION DUMP
"\xf6\x05test3\x03LUA\x00@Fredis.register_function('f5', function(keys, args) while 1 do end end)\n\x00wY\xbb \xec\x0f\x91i"
> FUNCTION FLUSH
OK
> FUNCTION RESTORE "\xf6\x05test3\x03LUA\x00@Fredis.register_function('f5', function(keys, args) while 1 do end end)\n\x00wY\xbb \xec\x0f\x91i"
OK
127.0.0.1:6379> FUNCTION LIST
1) 1) "library_name"
   1) "test3"
   2) "engine"
   3) "LUA"
   4) "description"
   5) (nil)
   6) "functions"
   7) 1) 1) "name"
         1) "f5"
         2) "description"
         3) (nil)
```
