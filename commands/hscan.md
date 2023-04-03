See `SCAN` for `HSCAN` documentation.

@return

@array-reply: specifically, an array with two elements.
The first element is a @bulk-string-reply that represents an unsigned 64-bit number (the cursor).
The second element is an @array-reply, where each element is a two-element @array-reply for each field-value tuple that was scanned.
