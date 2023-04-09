Returns the cardinality (number of elements) of the [Redis set](/docs/data-types/sets) stored at _key_.

@return

@integer-reply: the cardinality (number of elements) of the set, or `0` if _key_ doesn't exist.

@examples

```cli
SADD myset "Hello"
SADD myset "World"
SCARD myset
```
