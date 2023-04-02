Removes the first _count_ occurrences of elements equal to _element_ from the list stored at _key_.
The _count_ argument influences the operation in the following ways:

* `count > 0`: Remove elements equal to _element_ moving from head to tail.
* `count < 0`: Remove elements equal to _element_ moving from tail to head.
* `count = 0`: Remove all elements equal to _element_.

For example, `LREM list -2 "hello"` will remove the last two occurrences of
"hello" in the list stored at "list".

Note that non-existing keys are treated like empty lists, so when _key_ doesn't exist, the command will always return `0`.

@return

@integer-reply: the number of removed elements.

@examples

```cli
RPUSH mylist "hello"
RPUSH mylist "hello"
RPUSH mylist "foo"
RPUSH mylist "hello"
LREM mylist -2 "hello"
LRANGE mylist 0 -1
```
