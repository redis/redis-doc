

Sort the elements contained in the [List][1], [Set][2], or
[Sorted Set][3] value at _key_. By defaul
sorting is numeric with elements being compared as double precision
floating point numbers. This is the simplest form of SORT:
`SORT mylist`
Assuming mylist contains a list of numbers, the return value will be
the list of numbers ordered from the smallest to the biggest number.
In order to get the sorting in reverse order use **DESC**:
`SORT mylist DESC`
The **ASC** option is also supported but it's the default so you don'
really need it.
If you want to sort lexicographically use **ALPHA**. Note that Redis is
utf-8 aware assuming you set the right value for the LC_COLLATE
environment variable.

Sort is able to limit the number of returned elements using the **LIMIT**
option:
`SORT mylist LIMIT 0 10`
In the above example SORT will return only 10 elements, starting from
the first one (start is zero-based). Almost all the sort options can
be mixed together. For example the command:
`SORT mylist LIMIT 0 10 ALPHA DESC`
Will sort _mylist_ lexicographically, in descending order, returning only
the first 10 elements.

Sometimes you want to sort elements using external keys as weights to
compare instead to compare the actual List Sets or Sorted Set elements.
For example the list _mylist_ may contain the elements 1, 2, 3, 4, tha
are just unique IDs of objects stored at object_1, object_2, object_3
and object_4, while the keys weight_1, weight_2, weight_3 and weight_4
can contain weights we want to use to sort our list of objects
identifiers. We can use the following command:

## Sorting by external keys

`SORT mylist BY weight_*`
the **BY** option takes a pattern (weight_* in our example) that is used
in order to generate the key names of the weights used for sorting.
Weight key names are obtained substituting the first occurrence of *
with the actual value of the elements on the list (1,2,3,4 in our example).

Our previous example will return just the sorted IDs. Often it is
needed to get the actual objects sorted (object_1, ..., object_4 in the
example). We can do it with the following command:

## Not Sorting at all

`SORT mylist BY nosort`
also the **BY** option can take a nosort specifier. This is useful if you
want to retrieve a external key (using GET, read below) but you don'
want the sorting overhead.

## Retrieving external keys

`SORT mylist BY weight_* GET object_*`
Note that **GET** can be used multiple times in order to get more keys for
every element of the original List, Set or Sorted Set sorted.

Since Redis = 1.1 it's possible to also GET the list elements itself
using the special # pattern:
`SORT mylist BY weight_* GET object_* GET #`

## Storing the result of a SORT operation

By default SORT returns the sorted elements as its return value.
Using the **STORE** option instead to return the elements SORT will
store this elements as a [Redis List][1] in the specified key.
An example:
`SORT mylist BY weight_* STORE resultkey`
An interesting pattern using SORT ... STORE consists in associating
an [EXPIRE][4] timeout to the resulting key so that in
applications where the result of a sort operation can be cached for
some time other clients will use the cached list instead to call SORT
for every request. When the key will timeout an updated version of
the cache can be created using SORT ... STORE again.

Note that implementing this pattern it is important to avoid that multiple
clients will try to rebuild the cached version of the cache
at the same time, so some form of locking should be implemented
(for instance using [SETNX][5]).

## SORT and Hashes: BY and GET by hash field

It's possible to use BY and GET options against Hash fields using the following syntax:
	SORT mylist BY weight_*-fieldname
	SORT mylist GET object_*-fieldnameThe two chars string - is used in order to signal the name of the Hash field. The key is substituted as documented above with sort BY and GET against normal keys, and the Hash stored at the resulting key is accessed in order to retrieve the specified field.

## Return value

[Multi bulk reply][6], specifically a list of sorted elements.



[1]: /p/redis/wiki/Lists
[2]: /p/redis/wiki/Sets
[3]: /p/redis/wiki/SortedSets
[4]: /p/redis/wiki/ExpireCommand
[5]: /p/redis/wiki/SetnxCommand
[6]: /p/redis/wiki/ReplyTypes
