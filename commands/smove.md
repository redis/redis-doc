@complexity

O(1)


Move the specifided _member_ from the set at _srckey_ to the set at _dstkey_.
This operation is atomic, in every given moment the element will appear to
be in the source or destination set for accessing clients.

If the source set does not exist or does not contain the specified elemen
no operation is performed and zero is returned, otherwise the element is
removed from the source set and added to the destination set. On success
one is returned, even if the element was already present in the destination
set.

An error is raised if the source or destination keys contain a non Set value.

@return

@integer-reply, specifically:

    1 if the element was moved
    0 if the element was not found on the first set and no operation was performed



[1]: /p/redis/wiki/ReplyTypes