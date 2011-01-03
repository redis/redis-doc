@complexity

O(1)


Atomically returns and removes the last element (tail) of the list stored at
`source`, and pushes the element at the first element (head) of the list stored
at `destination`.

For example: consider `source` holding the list `a,b,c`, and `destination`
holding the list `x,y,z`. Executing `RPOPLPUSH` results in `source` holding
`a,b` and `destination` holding `c,x,y,z`.

If `source` does not exist, the value `nil` is returned and no operation is
performed. If `source` and `destination` are the same, the operation is
equivalent to removing the last element from the list and pushing it as first
element of the list, so it can be considered as a list rotation command.

@return

@bulk-reply: the element being popped and pushed.

@examples

    @cli
    RPUSH mylist "one"
    RPUSH mylist "two"
    RPUSH mylist "three"
    RPOPLPUSH mylist myotherlist
    LRANGE mylist 0 -1
    LRANGE myotherlist 0 -1

## Design pattern: safe queues

Redis lists are often used as queues in order to exchange messages between
different programs. A program can add a message performing an `LPUSH` operation
against a Redis list (we call this program the _Producer_), while another program
(that we call _Consumer_) can process the messages performing an `RPOP` command
in order to start reading the messages starting at the oldest.

Unfortunately, if a _Consumer_ crashes just after an `RPOP` operation, the message
is lost. `RPOPLPUSH` solves this problem since the returned message is
added to another backup list. The _Consumer_ can later remove the message
from the backup list using the `LREM` command when the message was correctly
processed.

Another process (that we call _Helper_), can monitor the backup list to check for
timed out entries to repush against the main queue.

## Design pattern: server-side O(N) list traversal

Using `RPOPLPUSH` with the same source and destination key, a process can
visit all the elements of an N-elements list in O(N) without transferring
the full list from the server to the client in a single `LRANGE` operation.
Note that a process can traverse the list even while other processes
are actively `RPUSH`-ing against the list, and still no element will be skipped.

