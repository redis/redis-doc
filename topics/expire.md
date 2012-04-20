## How Redis expires keys

Redis keys are expired in two ways: a passive way, and an active way.

A key is actively expired simply when some client tries to access it, and
the key is found to be timed out.

Of course this is not enough as there are expired keys that will never
be accessed again. This keys should be expired anyway, so periodically
Redis test a few keys at random among keys with an expire set.
All the keys that are already expired are deleted from the keyspace.

Specifically this is what Redis does 10 times per second:

1. Test 100 random keys from the set of keys with an associated expire.
2. Delete all the keys found expired.
3. If more than 25 keys were expired, start again from step 1.

This is a trivial probabilistic algorithm, basically the assumption is
that our sample is representative of the whole key space,
and we continue to expire until the percentage of keys that are likely
to be expired is under 25%

This means that at any given moment the maximum amount of keys already
expired that are using memory is at max equal to max amount of write
operations per second divided by 4.

## How expires are handled in the replication link and AOF file

In order to obtain a correct behavior without sacrificing consistency, when
a key expires, a `DEL` operation is synthesized in both the AOF file and gains
all the attached slaves. This way the expiration process is centralized in
the master instance, and there is no chance of consistency errors.

However while the slaves connected to a master will not expire keys
independently (but will wait for the `DEL` coming from the master), they'll
still take the full state of the expires existing in the dataset, so when a
slave is elected to a master it will be able to expire the keys
independently, fully acting as a master.
