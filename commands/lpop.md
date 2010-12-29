@complexity

O(1)


Removes and returns the first element of the list stored at `key`.

@return

@bulk-reply: the value of the first element, or `nil` when `key` does not exist.

@examples

    @cli
    RPUSH list "one"
    RPUSH list "two"
    RPUSH list "three"
    LPOP list
    LRANGE list 0 -1

