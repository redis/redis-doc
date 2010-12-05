@complexity

O(1)


Removes and returns the first element of the list stored at `key`.

@return

@bulk-reply: the value of the first element, or `nil` when `key` does not exist.

@examples

    RPUSH list "one"
    1
    RPUSH list "two"
    2
    RPUSH list "three"
    3
    LPOP list
    "one"
    LRANGE list 0 -1
    1) "two"
    2) "three"

