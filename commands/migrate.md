Atomically transfer one or more keys from the current Redis instance to a destination Redis instance.
On success, the key is deleted from the original instance and is guaranteed to exist in the target instance.

The command is atomic and blocks the two instances for the time required to transfer the key, at any given time the key will appear to exist only in one of the instances unless a timeout error occurs.
As of Redis 3.2 and above, multiple keys can be pipelined in a single call to `MIGRATE` by passing the empty string (`""`) as the key and adding the `!KEYS` clause.

The command internally uses `DUMP` to generate the serialized version of the keys' values and `RESTORE` to synthesize the key in the target instance.
The source instance acts as a client for the destination instance.
If the destination instance returns OK to the `RESTORE` command, the source instance deletes the key using `DEL`.

The _timeout_ specifies the maximum idle time in any moment of the communication with the destination instance in milliseconds.
This means that the operation does not need to be completed within the specified amount of milliseconds, but that the transfer should make progress without blocking for more than the specified amount of milliseconds.

`MIGRATE` needs to perform I/O operations and honor the specified timeout.
When there is an I/O error during the transfer or if the _timeout_ is reached the operation is aborted and the special error - `IOERR` returned.
When this happens the following two cases are possible:

* The key may be in both instances.
* The key may be only in the source instance.

The key can't get lost in the event of a timeout, but the client calling `MIGRATE`, in the event of a timeout error, should check if the key is **also present** in the target instance and act accordingly.

When any other error is returned (starting with `ERR`) `MIGRATE` guarantees that the key is still only present in the originating instance (unless a key with the same name was **also already present** on the target instance).

If there are no keys to migrate in the source instance `NOKEY` is returned.
Because missing keys are possible in normal conditions, due to expiry for example, `NOKEY` isn't an error. 

## Migrating multiple keys with a single command call

Starting with Redis 3.0.6, `MIGRATE` supports a new bulk-migration mode that uses pipelining to migrate multiple keys between instances without incurring the round trip time latency and other overheads that there are when moving each key with a single `MIGRATE` call.

To enable this form, the `!KEYS` option is used, and the normal _key_ argument is set to an empty string.
The actual key names will be provided after the `!KEYS` argument itself, like in the following example:

    MIGRATE 192.168.1.34 6379 "" 0 5000 KEYS key1 key2 key3

When this form is used the `NOKEY` status code is only returned when none of the keys is present in the instance.
Otherwise, the command is executed, even if just a single key exists.

## Options

* `!COPY` -- Do not remove the key from the local instance.
* `REPLACE` -- Replace the existing key on the remote instance.
* `!KEYS` -- If the key argument is an empty string, the command will instead migrate all the keys that follow the `!KEYS` option (see the above section for more info).
* `!AUTH` -- Authenticate with the given password to the remote instance.
* `AUTH2` -- Authenticate with the given username and password pair (Redis 6 or greater ACL auth style).

@return

@simple-string-reply: The command returns `OK` on success, or `NOKEY` if no keys were found in the source instance.
