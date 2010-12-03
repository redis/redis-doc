

Move the specified key from the currently selected DB to the specified
destination DB. Note that this command returns 1 only if the key was
successfully moved, and 0 if the target key was already there or if the
source key was not found at all, so it is possible to use `MOVE` as a locking
primitive.

@return

@integer-reply, specifically:

    1 if the key was moved
    0 if the key was not moved because already present on the target DB or was not found in the current DB.
