@complexity

O(N) where N is the number of keys to set


Sets the given keys to their respective values. `MSETNX` will not perform any
operation at all even if just a single key already exists.

Because of this semantic `MSETNX` can be used in order to set different keys
representing different fields of an unique logic object in a way that
ensures that either all the fields or none at all are set.

`MSETNX` is atomic, so all given keys are set at once. It is not possible for
clients to see that some of the keys were updated while others are unchanged.

@return

@integer-reply, specifically:

* `1` if the all the keys were set.
* `0` if no key was set (at least one key already existed).

