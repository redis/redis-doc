@complexity

O(1)


Increment or decrement the number stored at _key_ by one. If the key does
not exist or contains a value of a wrong type, set the key to the
value of 0 before to perform the increment or decrement operation.

INCRBY and DECRBY work just like INCR and DECR but instead to
increment/decrement by 1 the increment/decrement is _integer_.

INCR commands are limited to 64 bit signed integers.

Note: this is actually a string operation, that is, in Redis there are no
integer types. Simply the string stored at the key is parsed as a base 10 64
bit signed integer, incremented, and then converted back as a string.

@return

@integer-reply, this commands will reply with the new value of _key_ after
the increment or decrement.



[1]: /p/redis/wiki/ReplyTypes
