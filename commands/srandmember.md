@complexity

O(1)


Returns a random element from the set value stored at `key`.

This operation is similar to `SPOP`, that also removes the randomly
selected element.

@return

@bulk-reply: the randomly selected element, or `nil` when `key` does not exist.

