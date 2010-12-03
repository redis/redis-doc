@complexity

O(N) (with N being the length of the list)


Remove the first _count_ occurrences of the _value_ element from the list.
If _count_ is zero all the elements are removed. If _count_ is negative
elements are removed from tail to head, instead to go from head to tail
that is the normal behaviour. So for example `LREM` with count -2 and
_hello_ as value to remove against the list (a,b,c,hello,x,hello,hello) will
lave the list (a,b,c,hello,x). The number of removed elements is returned
as an integer, see below for more information about the returned value.
Note that non existing keys are considered like empty lists by `LREM`, so `LREM`
against non existing keys will always return 0.

@return

@integer-reply, specifically:

`The number of removed elements if the operation succeeded`
