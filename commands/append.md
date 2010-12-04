@complexity

O(1). The amortized time complexity is O(1) assuming the appended value is
small and the already present value is of any size, since the dynamic string
library used by Redis will double the free space available on every
reallocation.

If `key` already exists and is a string, this command appends the `value` at
the end of the string.  If `key` does not exist it is created and set as an
empty string, so `APPEND` will be similar to `SET` in this special case.

@return

@integer-reply: the length of the string after the append operation.

@examples

    EXISTS mykey
    (integer) 0
    APPEND mykey "Hello "
    (integer) 6
    APPEND mykey "World"
    (integer) 11
    GET mykey
    Hello World

