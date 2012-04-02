Atomically transfer a key from a source Redis instance to a destination Redis instance. On success the key is deleted from the original instance and is guaranteed to exist in the target instance.

The command is atomic and blocks the two instances for the time required to transfer the key, at any given time the key will appear to exist in a given instance or in the other instance, unless a timeout error occurs.

The command internally uses `DUMP` to generate the serialized version of the key value, and `RESTORE` in order to synthesize the key in the target instance.
The source instance acts as a client for the target instance. If the target instance returns OK to the `RESTORE` command, the source instance deletes the key using `DEL`.

The timeout specifies the maximum idle time in any moment of the communication with the destination instance in milliseconds. If this idle time is reached the operation is aborted, an error returned, and one of the following cases are possible:

* The key may be on both the instances.
* The key may be only in the source instance.

It is not possible for the key to get lost in the event of a timeout, but the client calling `MIGRATE`, in the event of a timeout error, should check if the key is *also* present in the target instance and act accordingly.

On success OK is returned, otherwise an error is returned.
If the error is a timeout the special error -TIMEOUT is returned so that clients can distinguish between this and other errors.

@return

@status-reply: The command returns OK on success.
