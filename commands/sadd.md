@complexity

O(1)


Add the specified _member_ to the set value stored at _key_. If _member_
is already a member of the set no operation is performed. If _key_
does not exist a new set with the specified _member_ as sole member is
created. If the key exists but does not hold a set value an error is
returned.

@return

@integer-reply, specifically:

    1 if the new element was added
    0 if the element was already a member of the se
