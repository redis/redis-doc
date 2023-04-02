Atomically returns and removes the last element (tail) of the list stored at _source_, and pushes the element at the first element (head) of the list stored at _destination_.

For example: consider a key called "src" with the list "a", "b" and "c", and a "dst" key with the list "x", "y" and "z".
Executing `RPOPLPUSH src dst` results in "src" consisting of "a" and "b", and "dst"
of "c", "x", "y" and "z".

If _source_ doesn't exist, the value `nil` is returned and no operation is performed.
If _source_ and _destination_ are the same, the operation is equivalent to removing the last element from the list and pushing it as the first element of the list, so it can be considered a list rotation command.

{{% alert title="Note" color="info" %}}
A Redis list always consists of one or element.
When the last element is popped, the list is automatically deleted from the database.
{{% /alert  %}}

@return

@bulk-string-reply: the element being popped and pushed.

@examples

```cli
RPUSH mylist "one"
RPUSH mylist "two"
RPUSH mylist "three"
RPOPLPUSH mylist myotherlist
LRANGE mylist 0 -1
LRANGE myotherlist 0 -1
```

## Pattern: Reliable queue

Redis is often used as a messaging server to implement processing of background
jobs or other kinds of messaging tasks.
A simple form of queue is often obtained pushing values into a list in the
producer side, and waiting for this values in the consumer side using `RPOP`
(using polling), or `BRPOP` if the client is better served by a blocking
operation.

However in this context the obtained queue is not _reliable_ as messages can
be lost, for example in the case there is a network problem or if the consumer
crashes just after the message is received but before it can be processed.

`RPOPLPUSH` (or `BRPOPLPUSH` for the blocking variant) offers a way to avoid
this problem: the consumer fetches the message and at the same time pushes it
into a _processing_ list.
It will use the `LREM` command in order to remove the message from the
_processing_ list once the message has been processed.

An additional client may monitor the _processing_ list for items that remain
there for too much time, pushing timed out items into the queue
again if needed.

## Pattern: Circular list

Using `RPOPLPUSH` with the same source and destination key, a client can visit
all the elements of an N-elements list, one after the other, in O(N) without
transferring the full list from the server to the client using a single `LRANGE`
operation.

The above pattern works even if one or both of the following conditions occur:

* There are multiple clients rotating the list: they'll fetch different 
  elements, until all the elements of the list are visited, and the process 
  restarts.
* Other clients are actively pushing new items at the end of the list.

The above makes it very simple to implement a system where a set of items must
be processed by N workers continuously as fast as possible.
An example is a monitoring system that must check that a set of web sites are
reachable, with the smallest delay possible, using a number of parallel workers.

Note that this implementation of workers is trivially scalable and reliable,
because even if a message is lost the item is still in the queue and will be
processed at the next iteration.
