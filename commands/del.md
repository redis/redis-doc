@complexity

O(N) where N is the number of keys that will be removed. When a key to remove
holds a value other than a string, the individual complexity for this key is
O(M) where M is the number of elements in the list, set, sorted set or hash.
Removing a single key that holds a string value is O(1).

Removes the specified keys.  A key is ignored if it does not exist.

@return

@integer-reply: The number of keys that were removed.

