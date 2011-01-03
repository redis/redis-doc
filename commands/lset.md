@complexity

O(N) where N is the length of the list. Setting either the first or the last
element of the list is O(1).

Sets the list element at `index` to `value`. For more information on the
`index` argument, see `LINDEX`.

An error is returned for out of range indexes.

@return

@status-reply

@examples

    @cli
    RPUSH mylist "one"
    RPUSH mylist "two"
    RPUSH mylist "three"
    LSET mylist 0 "four"
    LSET mylist -2 "five"
    LRANGE mylist 0 -1

