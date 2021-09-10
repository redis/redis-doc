Inserts specified values at the tail of the list stored at `key`, only if `key`
already exists and holds a list.
In contrary to `RPUSH`, no operation will be performed when `key` does not yet
exist.

@return

@integer-reply: the length of the list after the push operation.

@history

* `>= 4.0`: Accepts multiple `element` arguments.
  In Redis versions older than 4.0 it was possible to push a single value per
  command.

@examples

```cli
RPUSH mylist "Hello"
RPUSHX mylist "World"
RPUSHX myotherlist "World"
LRANGE mylist 0 -1
LRANGE myotherlist 0 -1
```
