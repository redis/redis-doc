Atomically transfer a key from a source Redis instance to a destination Redis
instance.
On success the key is deleted from the original instance and is guaranteed to
exist in the target instance.

The command is atomic and blocks the two instances for the time required to
transfer the key, at any given time the key will appear to exist in a given
instance or in the other instance, unless a timeout error occurs. In 3.2 and
above, multiple keys can be pipelined in a single call to `MIGRATE` by passing
the empty string ("") as key and adding the `KEYS` clause.

The command internally uses `DUMP` to generate the serialized version of the key
value, and `RESTORE` in order to synthesize the key in the target instance.
The source instance acts as a client for the target instance.
If the target instance returns OK to the `RESTORE` command, the source instance
deletes the key using `DEL`.

The timeout specifies the maximum idle time in any moment of the communication
with the destination instance in milliseconds.
This means that the operation does not need to be completed within the specified
amount of milliseconds, but that the transfer should make progresses without
blocking for more than the specified amount of milliseconds.

`MIGRATE` needs to perform I/O operations and to honor the specified timeout.
When there is an I/O error during the transfer or if the timeout is reached the
operation is aborted and the special error - `IOERR` returned.
When this happens the following two cases are possible:

* The key may be on both the instances.
* The key may be only in the source instance.

It is not possible for the key to get lost in the event of a timeout, but the
client calling `MIGRATE`, in the event of a timeout error, should check if the
key is _also_ present in the target instance and act accordingly.

When any other error is returned (starting with `ERR`) `MIGRATE` guarantees that
the key is still only present in the originating instance (unless a key with the
same name was also _already_ present on the target instance).

If there are no keys to migrate in the source instance `NOKEY` is returned.
Because missing keys are possible in normal conditions, from expiry for example,
`NOKEY` isn't an error. 

## Options

* `COPY` -- Do not remove the key from the local instance.
* `REPLACE` -- Replace existing key on the remote instance.

`COPY` and `REPLACE` are available only in 3.0 and above.

@return

@simple-string-reply: The command returns OK on success, or `NOKEY` if no keys were
found in the source instance.  
