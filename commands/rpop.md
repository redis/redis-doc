@complexity

O(1)


Removes and returns the last element of the list stored at `key`.

@return

@bulk-reply: the value of the last element, or `nil` when `key` does not exist.

@examples

    RPUSH list "one"
    1
    RPUSH list "two"
    2
    RPUSH list "three"
    3
    RPOP list
    "three"
    LRANGE list 0 -1
    1) "one"
    2) "two"

