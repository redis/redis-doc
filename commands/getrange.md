Returns the substring of the [Redis string](/docs/data-types/strings) value stored at _key_, determined by the offsets _start_ and _end_ (both are inclusive).
Negative offsets can be used to provide an offset starting from the end of the string.
So -1 means the last character, -2 the penultimate and so forth.

The function handles out-of-range requests by limiting the resulting range to the actual length of the string.

@return

@bulk-string-reply: the range from the string.

@examples

```cli
SET mykey "This is a string"
GETRANGE mykey 0 3
GETRANGE mykey -3 -1
GETRANGE mykey 0 -1
GETRANGE mykey 10 100
```
