@complexity

O(1), not counting the time taken to copy the new string in place. Usually,
this string is very small so the amortized complexity is O(1). Otheriwse,
complexity is O(M) with M being the length of the _value_ argument.

Overwrites part of the string stored at _key_, starting at the specified
offset, for the entire length of _value_. If the offset is larger than the
current length of the string at _key_, the string is padded with zero-bytes to
make _offset_ fit. Non-existing keys are considered as empty strings, so this
command will make sure it holds a string large enough to be able to set _value_
at _offset_.

Note that the maximum offset that you can set is 2^29 -1 (536870911), as Redis
Strings are limited to 512 megabytes. If you need to grow beyond this size, you
can use multiple keys.

**Warning**: When setting the last possible byte and the string value stored at
_key_ does not yet hold a string value, or holds a small string value, Redis
needs to allocate all intermediate memory which can block the server for some
time.  On a 2010 Macbook Pro, setting byte number 536870911 (512MB allocation)
takes ~300ms, setting byte number 134217728 (128MB allocation) takes ~80ms,
setting bit number 33554432 (32MB allocation) takes ~30ms and setting bit
number 8388608 (8MB allocation) takes ~8ms. Note that once this first
allocation is done, subsequent calls to `SETRANGE` for the same _key_ will not
have the allocation overhead.

## Patterns

Thanks to `SETRANGE` and the analogous `GETRANGE` commands, you can use Redis strings
as a linear array with O(1) random access. This is a very fast and
efficient storage in many real world use cases.

@return

@integer-reply: the length of the string after it was modified by the command.

@examples

Basic usage, setting a range:

    redis> set foo "Hello World"
    OK
    redis> setrange foo 6 "Redis"
    (integer) 11
    redis> get foo
    "Hello Redis"

Example of zero padding:

    redis> del foo
    (integer) 1
    redis> setrange foo 10 bar
    (integer) 13
    redis> get foo
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00bar"

