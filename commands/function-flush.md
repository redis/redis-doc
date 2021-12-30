Deletes all the libraries.

When called without the optional mode argument, the behavior is determined by the
`lazyfree-lazy-user-flush` configuration directive. Valid modes are:

* ASYNC: Asynchronously flush the libraries.
* SYNC: Synchronously flush the libraries.

For more information about functions please refer to [Introduction to Redis Functions](/topics/function)

@return

@simple-string-reply

@examples
```
> FUNCTION LIST
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
2) 1) "library_name"
   2) "test1"
   3) "engine"
   4) "LUA"
   5) "description"
   6) (nil)
   7) "functions"
   8) 1) 1) "name"
         2) "f3"
         3) "description"
         4) (nil)
      2) 1) "name"
         2) "f4"
         3) "description"
         4) (nil)
3) 1) "library_name"
   2) "test"
   3) "engine"
   4) "LUA"
   5) "description"
   6) (nil)
   7) "functions"
   8) 1) 1) "name"
         2) "f2"
         3) "description"
         4) (nil)
      2) 1) "name"
         2) "f1"
         3) "description"
         4) (nil)
> FUNCTION FLUSH
OK
> FUNCTION LIST
(empty array)
```