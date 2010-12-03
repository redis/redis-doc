@complexity

O(log(N))


`ZRANK` returns the rank of the member in the sorted set, with scores ordered from low to high. `ZREVRANK` returns the rank with scores ordered from high to low. When the given member does not exist in the sorted set, the special value 'nil' is returned. The returned rank (or index) of the member is 0-based for both commands.

@return

@integer-reply or a @nil-reply, specifically:

    the rank of the element as an integer reply if the element exists.
    A nil bulk reply if there is no such element.
