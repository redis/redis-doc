@complexity

O(N) where N is the total number of elements in all given sets.

Returns the members of the set resulting from the difference between the first
set and all the successive sets.

For example:

    key1 = {a,b,c,d}
    key2 = {c}
    key3 = {a,c,e}
    SDIFF key1 key2 key3 = {b,d}

Keys that do not exist are considered to be empty sets.

@return

@multi-bulk-reply: list with members of the resulting set.

