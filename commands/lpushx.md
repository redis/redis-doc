Inserts specified values at the head of the [Redis list](/docs/data-types/lists) stored at the _key_, only if the _key_ already exists and holds a list.
In contrast to `LPUSH`, no operation will be performed when the _key_ doesn't exist.

@return

@integer-reply: the length of the list after the push operation.

@examples

```cli
LPUSH mylist "World"
LPUSHX mylist "Hello"
LPUSHX myotherlist "Hello"
LRANGE mylist 0 -1
LRANGE myotherlist 0 -1
```
