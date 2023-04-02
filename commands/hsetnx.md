Sets _field_ in the hash stored at _key_ to _value_, if and only if _field_ doesn't exist yet.
If _key_ doesn't exist, a new key is created for the hash.
If _field_ already exists, this operation has no effect.

@return

@integer-reply, specifically:

* `1` if _field_ is a new field in the hash and the _value_ was set.
* `0` if _field_ already exists in the hash and no operation was performed.

@examples

```cli
HSETNX myhash field "Hello"
HSETNX myhash field "World"
HGET myhash field
```
