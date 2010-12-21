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

    SET s This is a string
    OK

    GETRANGE s 0 3
    This

    GETRANGE s -3 -1
    ing

    GETRANGE s 0 -1
    This is a string

    GETRANGE s 9 100000
    string

