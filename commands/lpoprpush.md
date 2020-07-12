Atomically returns and removes the first element (head) of the list stored at
`source`, and pushes the element at the last element (tail) of the list stored
at `destination`.

For example: consider `source` holding the list `a,b,c`, and `destination`
holding the list `x,y,z`.
Executing `LPOPRPUSH` results in `source` holding `b,c` and `destination`
holding `x,y,z,a`.

If `source` does not exist, the value `nil` is returned and no operation is
performed.
If `source` and `destination` are the same, the operation is equivalent to
removing the first element from the list and pushing it as last element of the
list, so it can be considered as a list rotation command.

@return

@bulk-string-reply: the element being popped and pushed.

@examples

```cli
RPUSH mylist "one"
RPUSH mylist "two"
RPUSH mylist "three"
LPOPRPUSH mylist myotherlist
LRANGE mylist 0 -1
LRANGE myotherlist 0 -1
```

## Pattern: Reliable queue

Please see the pattern description in the `RPOPLPUSH` documentation.

## Pattern: Circular list

Please see the pattern description in the `RPOPLPUSH` documentation.

