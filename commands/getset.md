Atomically sets _key_ to _value_ and returns the old value stored at _key_.
Returns an error when _key_ exists but does not hold a string value.
Any previous time-to0live associated with the key is discarded on successful `SET` operation.

## Design pattern

`GETSET` can be used together with `INCR` for counting with atomic reset.
For example: a process may call `INCR` against the key `mycounter` every time
some event occurs, but from time to time we need to get the value of the counter
and reset it to zero atomically.
This can be done using `GETSET mycounter "0"`:

```cli
INCR mycounter
GETSET mycounter "0"
GET mycounter
```

@return

@bulk-string-reply: the old value stored at _key_, or @nil-reply when _key_ doesn't exist.

@examples

```cli
SET mykey "Hello"
GETSET mykey "World"
GET mykey
```
