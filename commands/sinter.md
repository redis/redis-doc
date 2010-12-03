@complexity

O(N*M) worst case where N is the cardinality of the smalles
set and M the number of sets_

Return the members of a set resulting from the intersection of all the
sets hold at the specified keys. Like in `LRANGE` the result is sent to
the client as a multi-bulk reply (see the protocol specification for
more information). If just a single key is specified, then this command
produces the same result as `SMEMBERS`. Actually `SMEMBERS` is just syntax
sugar for SINTERSECT.

Non existing keys are considered like empty sets, so if one of the keys is
missing an empty set is returned (since the intersection with an empty
set always is an empty set).

@return

@multi-bulk-reply, specifically the list of common elements.
