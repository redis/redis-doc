Inserts specified values at the tail of the [Redis list](/docs/data-types/lists) stored at _key_, if and only if the _key_ already exists and has a list value.
In contrast to `RPUSH`, no operation will be performed when _key_ doesn't exist.

@return

@integer-reply: the length of the list after the push operation.

@examples

```cli
RPUSH mylist "Hello"
RPUSHX mylist "World"
RPUSHX myotherlist "World"
LRANGE mylist 0 -1
LRANGE myotherlist 0 -1
```
