This command iterates the members of a [Redis set](/docs/data-types/sets) stored at _key_.

See `SCAN` for `SSCAN` documentation.

@return

@array-reply: specifically, an array with two elements.
The first element is a @bulk-string-reply that represents an unsigned 64-bit number (the cursor).
The second element is an @array-reply with the names of scanned members.
