@complexity

O(1)


SETNX works exactly like [SET][1] with the only difference tha
if the key already exists no operation is performed.
SETNX actually means SET if Not eXists.

## Return value

[Integer reply][2], specifically:

	1 if the key was se
	0 if the key was not se

## Design pattern: Implementing locking with SETNX

SETNX can also be seen as a locking primitive. For instance to acquire
the lock of the key **foo**, the client could try the following:
`SETNX lock.foo current UNIX time + lock timeout + 1`
If SETNX returns 1 the client acquired the lock, setting the **lock.foo**
key to the UNIX time at witch the lock should no longer be considered valid.
The client will later use **DEL lock.foo** in order to release the lock.

If SETNX returns 0 the key is already locked by some other client. We can
either return to the caller if it's a non blocking lock, or enter a
loop retrying to hold the lock until we succeed or some kind of timeou
expires.

### Handling deadlocks

In the above locking algorithm there is a problem: what happens if a clien
fails, crashes, or is otherwise not able to release the lock?
It's possible to detect this condition because the lock key contains a
UNIX timestamp. If such a timestamp is = the current Unix time the lock
is no longer valid.

When this happens we can't just call DEL against the key to remove the lock
and then try to issue a SETNX, as there is a race condition here, when
multiple clients detected an expired lock and are trying to release it.

* C1 and C2 read lock.foo to check the timestamp, because SETNX returned 0 to both C1 and C2, as the lock is still hold by C3 that crashed after holding the lock.
* C1 sends DEL lock.foo
* C1 sends SETNX = success!
* C2 sends DEL lock.foo
* C2 sends SETNX = success!
* ERROR: both C1 and C2 acquired the lock because of the race condition.

Fortunately it's possible to avoid this issue using the following algorithm.
Let's see how C4, our sane client, uses the good algorithm:

* C4 sends SETNX lock.foo in order to acquire the lock
* The crashed C3 client still holds it, so Redis will reply with 0 to C4.
* C4 GET lock.foo to check if the lock expired. If not it will sleep one second (for instance) and retry from the start.
* If instead the lock is expired because the UNIX time at lock.foo is older than the current UNIX time, C4 tries to perform GETSET lock.foo current unix timestamp + lock timeout + 1
* Thanks to the [GETSET][3] command semantic C4 can check if the old value stored at key is still an expired timestamp. If so we acquired the lock!
* Otherwise if another client, for instance C5, was faster than C4 and acquired the lock with the GETSET operation, C4 GETSET operation will return a non expired timestamp. C4 will simply restart from the first step. Note that even if C4 set the key a bit a few seconds in the future this is not a problem.

IMPORTANT NOTE: In order to make this locking algorithm more robust, a clien
holding a lock should always check the timeout didn't expired before to unlock
the key with DEL because client failures can be complex, not just crashing
but also blocking a lot of time against some operation and trying to issue
DEL after a lot of time (when the LOCK is already hold by some other client).




[1]: /p/redis/wiki/SetCommand
[2]: /p/redis/wiki/ReplyTypes
[3]: /p/redis/wiki/GetsetCommand
