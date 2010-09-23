@complexity

O(1)

@description

Increment or decrement the number stored at `key` by one. If the key
does not exist or contains a value of a wrong type, set the key to the
value of 0 before to perform the increment or decrement operation.

``INCRBY`` and ``DECRBY`` work just like ``INCR`` and ``DECR`` but instead to
increment/decrement by 1 the increment/decrement is `integer`.

``INCR`` commands are limited to 64 bit signed integers.

Note: this is actually a string operation, that is, in Redis there are
no integer types. Simply the string stored at the key is parsed as a
base 10 64 bit signed integer, incremented, and then converted back as a
string.

@return

@integer-reply: the new value of `key` after the increment or decrement.