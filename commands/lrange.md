@complexity

O(S+N) where S is the `start` offset and N is the number of elements in the
specified range.

Returns the specified elements of the list stored at `key`.  The offsets
`start` and `end` are zero-based indexes, with `0` being the first element of
the list (the head of the list), `1` being the next element and so on.

These offsets can also be negative numbers indicating offsets starting at the
end of the list. For example, `-1` is the last element of the list, `-2` the
penultimate, and so on.

## Consistency with range functions in various programming languages

Note that if you have a list of numbers from 0 to 100, `LRANGE list 0 10` will
return 11 elements, that is, the rightmost item is included. This **may or may
not** be consistent with behavior of range-related functions in your
programming language of choice (think Ruby's `Range.new`, `Array#slice` or
Python's `range()` function).

## Out-of-range indexes

Out of range indexes will not produce an error. If `start` is larger than the
end of the list, or `start > end`, an empty list is returned.  If `end` is
larger than the actual end of the list, Redis will treat it like the last
element of the list.

@return

@multi-bulk-reply: list of elements in the specified range.

@examples

    RPUSH list "one"
    1
    RPUSH list "two"
    2
    RPUSH list "three"
    3
    LRANGE list 0 0
    1) "one"
    LRANGE list -3 2
    1) "one"
    2) "two"
    3) "three"
    LRANGE list -100 100
    1) "one"
    2) "two"
    3) "three"
    LRANGE list 5 10
    (empty list)

