Add the specified members to the set stored at _key_.
Specified members that are already a member of this set are ignored.
If _key_ doesn't exist, a new set is created before adding the specified members.

An error is returned when the value stored at _key_ is not a set.

@return

@integer-reply: the number of new members that were added to the set. Members that already exist in the set are not included.

@examples

```cli
SADD myset "Hello"
SADD myset "World"
SADD myset "World"
SMEMBERS myset
```
