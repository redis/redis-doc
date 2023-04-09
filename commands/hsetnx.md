Sets _field_ in the [Redis hash](/docs/data-types/hashes) stored at _key_ to _value_, if and only if the _field_ doesn't exist yet.

If the _key_ doesn't exist, a new key is created for the hash.
If the _field_ already exists, this operation has no effect.

@return

@integer-reply, specifically:

* `1` if the _field_ is new in the hash and the _value_ was set.
* `0` if the _field_ already exists in the hash and no operation was performed.

@examples

```cli
HSETNX myhash field "Hello"
HSETNX myhash field "World"
HGET myhash field
```
