@complexity

O(1)


Inserts `value` at the head of the list stored at `key`.  If `key` does not
exist, it is created as empty list before performing the push operation.
When `key` holds a value that is not a list, an error is returned.

@return

@integer-reply: the length of the list after the push operation.

@history

* `>= 2.4`: Accepts multiple `value` arguments.

@examples

    @cli
    LPUSH mylist "world"
    LPUSH mylist "hello"
    LRANGE mylist 0 -1

