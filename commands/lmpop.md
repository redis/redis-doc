Pops one ore more elements from the first non-empty list key from the list of provided key names.

Similar other commands have limitations:
- `LPOP` or `RPOP` which take only one key, and can return multiple elements.
- `BLPOP` or `BRPOP` which take multiple keys, but return only one element from just one key.

See `BLMPOP` for the blocking variant of this command.

Search the list from left to right, find the first non-empty list, return the corresponding list key name, pop from the left or right depending on the argument given, and return the elements.
The number of returned elements will be limited to `count`(default 1) and the list length.

@return

@array-reply: specifically:

* A `nil` when no element could be popped.
* A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of elements.

@examples

```cli
LMPOP 2 non1 non2 LEFT COUNT 10
LPUSH mylist "one" "two" "three" "four" "five"
LMPOP 1 mylist LEFT
LRANGE mylist 0 -1
LMPOP 1 mylist RIGHT COUNT 10
LPUSH mylist "one" "two" "three" "four" "five"
LPUSH mylist2 "a" "b" "c" "d" "e"
LMPOP 2 mylist mylist2 right count 3
LRANGE mylist 0 -1
LMPOP 2 mylist mylist2 right count 5
LMPOP 2 mylist mylist2 right count 10
EXISTS mylist mylist2
```
