@complexity

O(1)


Removes and returns the last element of the list stored at `key`.

@return

@bulk-reply: the value of the last element, or `nil` when `key` does not exist.

@examples

    @cli
    RPUSH list "one"
    RPUSH list "two"
    RPUSH list "three"
    RPOP list
    LRANGE list 0 -1

