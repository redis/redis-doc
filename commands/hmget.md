@complexity

O(N) (with N being the number of fields)


Retrieve the values associated to the specified _fields_.

If some of the specified _fields_ do not exist, nil values are returned.
Non existing keys are considered like empty hashes.

@return

@multi-bulk-reply specifically a list of all the values associated with
the specified fields, in the same order of the request.
