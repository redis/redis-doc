@complexity

O(N) where N is the length of the returned string. The complexity is ultimately
determined by the returned length, but because creating a substring from an
existing string is very cheap, it can be considered O(1) for small strings.

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

    SUBSTR s 0 3
    This

    SUBSTR s -3 -1
    ing

    SUBSTR s 0 -1
    This is a string

    SUBSTR s 9 100000
    string

