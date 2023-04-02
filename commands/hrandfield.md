When called with just the _key_ argument, return a random field from the hash value stored at the _key_.

If the provided _count_ argument is positive, return an array of **distinct fields**.
The array's length is either _count_ or the hash's number of fields (`HLEN`), whichever is lower.

If called with a negative _count_, the behavior changes and the command is allowed to return the **same field multiple times**.
In this case, the number of returned fields is the absolute value of the specified _count_.

The optional `WITHVALUES` modifier changes the reply so it includes the respective values of the randomly selected hash fields.

@return

@bulk-string-reply: without the additional _count_ argument, the command returns a Bulk Reply with the randomly selected field, or @nil-reply when the _key_ doesn't exist.

@array-reply: when the additional _count_ argument is passed, the command returns an array of fields, or an empty array when _key_ doesn't exist.
If the `WITHVALUES` modifier is used, the reply is a list of fields and their values from the hash.

@examples

```cli
HMSET coin heads obverse tails reverse edge null
HRANDFIELD coin
HRANDFIELD coin
HRANDFIELD coin -5 WITHVALUES
```

## Specification of the behavior when count is passed

When the _count_ argument is a positive value this command behaves as follows:

* No repeated fields are returned.
* If the _count_ is bigger than the number of fields in the hash, the command will only return the whole hash without additional fields.
* The order of fields in the reply is not truly random, so it is up to the client to shuffle them if needed.

When the _count_ is a negative value, the behavior changes as follows:

* Repeating fields are possible.
* Exactly _count_ fields, or an empty array if the hash is empty (non-existing key), are always returned.
* The order of fields in the reply is truly random.
