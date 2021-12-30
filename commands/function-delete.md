Delete a function previously uploaded using `FUNCTION LOAD`.

This operation deletes all the functions registered by the library.
If the library does not exists, error is returned.

For more information about functions please refer to [Introduction to Redis Functions](/topics/function)

@return

@simple-string-reply

@examples
```
> function load Lua test "redis.register_function('f1', function(keys, args) return 'hello' end)"
OK
> fcall f1 0
"hello"
> function delete test
OK
127.0.0.1:6379> fcall f1 0
(error) ERR Function not found
```