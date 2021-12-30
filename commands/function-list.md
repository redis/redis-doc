Return information about the function and libraries.

It is possible to list only libraries that match a pattern using `LIBRARYNAME` argument.
It is also possible to retrieve the library code using `WITHCODE` argument.

Information given for each library:

* Library name
* Engine used to create the library
* Library description
* Function list
  * Function name
  * Function description
* Library code (with `WITHCODE` was requested)

For more information about functions please refer to [Introduction to Redis Functions](/topics/function)

@examples

The following example shows a list of 2 libraries each has 2 functions.

```
> function list
1) 1) "library_name"
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
2) 1) "library_name"
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

```