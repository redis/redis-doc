@complexity

O(1)


`BLPOP` (and `BRPOP`) is a blocking list pop primitive. You can see this commands
as blocking versions of `LPOP` and `RPOP` able to
block if the specified keys don't exist or contain empty lists.

The following is a description of the exact semantic. We describe `BLPOP` bu
the two commands are identical, the only difference is that `BLPOP` pops the
element from the left (head) of the list, and `BRPOP` pops from the right (tail).

## Non blocking behavior

When `BLPOP` is called, if at least one of the specified keys contain a non
empty list, an element is popped from the head of the list and returned to
the caller together with the name of the key (`BLPOP` returns a two elements
array, the first element is the key, the second the popped value).

Keys are scanned from left to right, so for instance if you
issue **`BLPOP` list1 list2 list3 0** against a dataset where **list1** does no
exist but **list2** and **list3** contain non empty lists, `BLPOP` guarantees
to return an element from the list stored at **list2** (since it is the firs
non empty list starting from the left).

## Blocking behavior

If none of the specified keys exist or contain non empty lists, `BLPOP`
blocks until some other client performs a `LPUSH` or
an `RPUSH` operation against one of the lists.

Once new data is present on one of the lists, the client finally returns
with the name of the key unblocking it and the popped value.

When blocking, if a non-zero timeout is specified, the client will unblock
returning a nil special value if the specified amount of seconds passed
without a push operation against at least one of the specified keys.

The timeout argument is interpreted as an integer value. A timeout of zero means instead to block forever.

## Multiple clients blocking for the same keys

Multiple clients can block for the same key. They are put into
a queue, so the first to be served will be the one that started to wai
earlier, in a first-blpopping first-served fashion.

## blocking POP inside a `MULTI`/`EXEC` transaction

`BLPOP` and `BRPOP` can be used with pipelining (sending multiple commands and reading the replies in batch), but it does not make sense to use `BLPOP` or `BRPOP` inside a `MULTI`/`EXEC` block (a Redis transaction).

The behavior of `BLPOP` inside `MULTI`/`EXEC` when the list is empty is to return a @nil-reply, exactly what  happens when the timeout is reached. If you like science fiction, think at it like if inside `MULTI`/`EXEC` the time will  flow at infinite speed :)

@return

`BLPOP` returns a two-elements array via a multi bulk reply in order to return
both the unblocking key and the popped value.

When a non-zero timeout is specified, and the `BLPOP` operation timed out,
the return value is a nil multi bulk reply. Most client values will return
false or nil accordingly to the programming language used.

@multi-bulk-reply



[1]: /p/redis/wiki/LpopCommand
[2]: /p/redis/wiki/RpushCommand
[3]: /p/redis/wiki/ReplyTypes