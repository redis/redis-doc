Inserts _element_ into the [Redis list](/docs/data-types/lists) stored at _key_ either before or after the reference value _pivot_.

When the _key_ doesn't exist, it is considered an empty list and no operation is performed.

An error is returned when the _key_ exists but doesn't hold a list value.

@return

@integer-reply: the list length after a successful insert operation, `0` if the _key_ doesn't exist, and `-1` when the _pivot_ wasn't found.

@examples

```cli
RPUSH mylist "Hello"
RPUSH mylist "World"
LINSERT mylist BEFORE "World" "There"
LRANGE mylist 0 -1
```
