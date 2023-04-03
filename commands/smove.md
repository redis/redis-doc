Move _member_ from the set at _source_ to the set at _destination_.
This operation is atomic.
In every given moment the element will appear to be a member of _source_ **or**
_destination_ to other clients.

If the _source_ set doesn't exist or doesn't contain the specified element, no
operation is performed and `0` is returned.
Otherwise, the member is removed from the _source_ set and added to the
_destination_ set.
When the specified member already exists in the _destination_ set, it is only
removed from the _source_ set.

An error is returned if either _source_ or _destination_ isn't a set.

@return

@integer-reply, specifically:

* `1` if the element is moved.
* `0` if the element is not a member of _source_ and no operation was performed.

@examples

```cli
SADD myset "one"
SADD myset "two"
SADD myotherset "three"
SMOVE myset myotherset "two"
SMEMBERS myset
SMEMBERS myotherset
```
