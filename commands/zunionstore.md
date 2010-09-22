

_Time complexity: O(N) + O(M log(M)) with N being the sum of the sizes of the
input sorted sets, and M being the number of elements in the resulting sorted
set_

Creates a union or intersection of _N_ sorted sets given by keys _k1_ through _kN_, and stores it at _dstkey_. It is mandatory to provide the number of input keys _N_, before passing the input keys and the other (optional) arguments.

As the terms imply, the ZINTERSTORE command requires an element to be present in each of the given inputs to be inserted in the result. The ZUNIONSTORE command inserts all elements across all inputs.

Using the WEIGHTS option, it is possible to add weight to each input sorted set. This means that the score of each element in the sorted set is first multiplied by this weight before being passed to the aggregation. When this option is not given, all weights default to 1.

With the AGGREGATE option, it's possible to specify how the results of the union or intersection are aggregated. This option defaults to SUM, where the score of an element is summed across the inputs where it exists. When this option is set to be either MIN or MAX, the resulting set will contain the minimum or maximum score of an element across the inputs where it exists.

## Return value

[Integer reply][1], specifically the number of elements in the sorted set a
_dstkey_.



[1]: /p/redis/wiki/ReplyTypes
