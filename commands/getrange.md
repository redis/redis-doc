@complexity

O(N) where N is the length of the returned string. The complexity is ultimately
determined by the returned length, but because creating a substring from an
existing string is very cheap, it can be considered O(1) for small strings.

**Warning**: this command was renamed to `GETRANGE`, it is called `SUBSTR` in Redis versions `<= 2.0`.

Returns the substring of the string value stored at `key`, determined by the
offsets `start` and `end` (both are inclusive). Negative offsets can be used in
order to provide an offset starting from the end of the string. So -1 means the
last character, -2 the penultimate and so forth.

The function handles out of range requests by limiting the resulting range to
the actual length of the string.

@return

@bulk-reply

@examples

    @cli
    SET key "This is a string"
    GETRANGE key 0 3
    GETRANGE key -3 -1
    GETRANGE key 0 -1
    GETRANGE key 10 100

