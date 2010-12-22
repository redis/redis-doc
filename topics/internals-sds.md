Hacking Strings
===

The implementation of Redis strings is contained in **sds.c** ( sds stands for Simple Dynamic Strings ).

The C structure _sdshdr_ declared in *sds.h* represents a Redis string:

    struct sdshdr {
        long len;
        long free;
        char buf[];
    };

The _buf_ character array stores the actual string.

The _len_ field stores the length of _buf_. This makes obtaining the length
of a Redis string an O(1) operation.

The _free_ field stores the number of additional bytes available for use.

Together the _len_ and _free_ field can be thought of as holding the metadata of the _buf_ character array.

Creating Redis Strings
---

A new data type named `sds` is defined in *sds.h* to be a synonymn for a character pointer:

    typedef char *sds;

`sdsnewlen` function defined in *sds.c* creates a new Redis String: 

    sds sdsnewlen(const void *init, size_t initlen) {
        struct sdshdr *sh;

        sh = zmalloc(sizeof(struct sdshdr)+initlen+1);
    #ifdef SDS_ABORT_ON_OOM
        if (sh == NULL) sdsOomAbort();
    #else
        if (sh == NULL) return NULL;
    #endif
        sh->len = initlen;
        sh->free = 0;
        if (initlen) {
            if (init) memcpy(sh->buf, init, initlen);
            else memset(sh->buf,0,initlen);
        }
        sh->buf[initlen] = '\0';
        return (char*)sh->buf;
    }

Remember a Redis string is a variable of type `struct sdshdr`. But `sdsnewlen` returns a character pointer!!

That's a trick and needs some explanation.

Suppose I create a Redis string using `sdsnewlen` like below:

    sdsnewlen("redis", 5);

This creates a new variable of type `struct sdshdr` allocating memory for _len_ and _free_
fields as well as for the _buf_ character array.

    sh = zmalloc(sizeof(struct sdshdr)+initlen+1); // initlen is length of init argument.

After `sdsnewlen` succesfully creates a Redis string the result is something like:

    -----------
    |5|0|redis|
    -----------
    ^   ^
    sh  sh->buf 

`sdsnewlen` returns sh->buf to the caller.

What do you do if you need to free the Redis string pointed by `sh`?

You want the pointer `sh` but you only have the pointer `sh->buf`.

Can you get the pointer `sh` from `sh->buf`?

Yes. Pointer arithmetic. Notice from the above ASCII art that if you subtract 
the size of two longs from `sh->buf` you get the pointer `sh`. 

The sizeof two longs happens to be the size of `struct sdshdr`.

Look at `sdslen` function and see this trick at work:

    size_t sdslen(const sds s) {
        struct sdshdr *sh = (void*) (s-(sizeof(struct sdshdr)));
        return sh->len;
    }

Knowing this trick you could easily go through the rest of the functions in *sds.c*.

The Redis string implementation is hidden behind an interface that accepts only character pointers. The users of Redis strings need not care about how its implemented and treat Redis strings as a character pointer.
