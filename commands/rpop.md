Removes and returns the last elements of the list stored at _key_.

By default, the command pops a single element from the end of the list.
When provided with the optional _count_ argument, the reply will consist of up to _count_ elements, depending on the list's length.

{{% alert title="Note" color="info" %}}
A Redis list always consists of at least one element.
When the last element is popped, the list is automatically deleted from the database.
{{% /alert %}}

@return

When called without the _count_ argument:

@bulk-string-reply: the value of the last element, or @nil-reply when _key_ doesn't exist.

When called with the _count_ argument:

@array-reply: list of popped elements, or @nil-reply when _key_ doesn't exist.

@examples

```cli
RPUSH mylist "one" "two" "three" "four" "five"
RPOP mylist
RPOP mylist 2
LRANGE mylist 0 -1
```
