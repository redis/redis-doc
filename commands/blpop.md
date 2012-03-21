`BLPOP` is a blocking list pop primitive.  It is the blocking version of `LPOP`
because it blocks the connection when there are no elements to pop from any of
the given lists. An element is popped from the head of the first list that is
non-empty, with the given keys being checked in the order that they are given.

## Non-blocking behavior

When `BLPOP` is called, if at least one of the specified keys contain a
non-empty list, an element is popped from the head of the list and returned to
the caller together with the `key` it was popped from.

Keys are checked in the order that they are given. Let's say that the key
`list1` doesn't exist and `list2` and `list3` hold non-empty lists. Consider
the following command:

    BLPOP list1 list2 list3 0

`BLPOP` guarantees to return an element from the list stored at `list2` (since
it is the first non empty list when checking `list1`, `list2` and `list3` in
that order).

## Blocking behavior

If none of the specified keys exist, `BLPOP` blocks
the connection until another client performs an `LPUSH` or `RPUSH` operation
against one of the keys.

Once new data is present on one of the lists, the client returns with the name
of the key unblocking it and the popped value.

When `BLPOP` causes a client to block and a non-zero timeout is specified, the
client will unblock returning a `nil` multi-bulk value when the specified
timeout has expired without a push operation against at least one of the
specified keys.

The timeout argument is interpreted as an integer value. A timeout of zero can
be used to block indefinitely.

## Multiple clients blocking for the same keys

Multiple clients can block for the same key. They are put into
a queue, so the first to be served will be the one that started to wait
earlier, in a first-`!BLPOP` first-served fashion.

## `!BLPOP` inside a `!MULTI`/`!EXEC` transaction

`BLPOP` can be used with pipelining (sending multiple commands and reading the
replies in batch), but it does not make sense to use `BLPOP` inside a
`MULTI`/`EXEC` block. This would require blocking the entire server in order to
execute the block atomically, which in turn does not allow other clients to
perform a push operation.

The behavior of `BLPOP` inside `MULTI`/`EXEC` when the list is empty is to
return a `nil` multi-bulk reply, which is the same thing that happens when the
timeout is reached. If you like science fiction, think of time flowing at
infinite speed inside a `MULTI`/`EXEC` block.

@return

@multi-bulk-reply: specifically:

* A `nil` multi-bulk when no element could be popped and the timeout expired.
* A two-element multi-bulk with the first element being the name of the key where an element
  was popped and the second element being the value of the popped element.

@examples

    redis> DEL list1 list2
    (integer) 0
    redis> RPUSH list1 a b c
    (integer) 3
    redis> BLPOP list1 list2 0
    1) "list1"
    2) "a"

## Pattern: Event notification

Using blocking list operations it is possible to mount different blocking
primitives. For instance for some application you may need to block
waiting for elements into a Redis Set, so that as far as a new element is
added to the Set, it is possible to retrieve it without resort to polling.
This would require a blocking version of `SPOP` that is
not available, but using blocking list operations we can easily accomplish
this task.

The consumer will do:

    LOOP forever
        WHILE SPOP(key) returns elements
            ... process elements ...
        END
        BRPOP helper_key
    END

While in the producer side we'll use simply:

    MULTI
    SADD key element
    LPUSH helper_key x
    EXEC


