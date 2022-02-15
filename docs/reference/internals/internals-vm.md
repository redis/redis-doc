---
title: "Virtual memory (deprecated)"
linkTitle: "Virtual memory"
weight: 1
aliases:
  - /topics/internals-vm
---

**Note: this document was written by the creator of Redis, Salvatore Sanfilippo, early in the development of Redis (c. 2010). Virtual Memory has been deprecated since Redis 2.6, so this documentation
is here only for historical interest.**

This document details the internals of the Redis Virtual Memory subsystem prior to Redis 2.6. The intended audience is not the final user but programmers willing to understand or modify the Virtual Memory implementation.

Keys vs Values: what is swapped out?
---

The goal of the VM subsystem is to free memory transferring Redis Objects from memory to disk. This is a very generic command, but specifically, Redis transfers only objects associated with _values_. In order to understand better this concept we'll show, using the DEBUG command, how a key holding a value looks from the point of view of the Redis internals:

    redis> set foo bar
    OK
    redis> debug object foo
    Key at:0x100101d00 refcount:1, value at:0x100101ce0 refcount:1 encoding:raw serializedlength:4

As you can see from the above output, the Redis top level hash table maps Redis Objects (keys) to other Redis Objects (values). The Virtual Memory is only able to swap _values_ on disk, the objects associated to _keys_ are always taken in memory: this trade off guarantees very good lookup performances, as one of the main design goals of the Redis VM is to have performances similar to Redis with VM disabled when the part of the dataset frequently used fits in RAM.

How does a swapped value looks like internally
---

When an object is swapped out, this is what happens in the hash table entry:

 * The key continues to hold a Redis Object representing the key.
 * The value is set to NULL

So you may wonder where we store the information that a given value (associated to a given key) was swapped out. Just in the key object!

This is how the Redis Object structure _robj_ looks like:

    /* The actual Redis Object */
    typedef struct redisObject {
        void *ptr;
        unsigned char type;
        unsigned char encoding;
        unsigned char storage;  /* If this object is a key, where is the value?
                                 * REDIS_VM_MEMORY, REDIS_VM_SWAPPED, ... */
        unsigned char vtype; /* If this object is a key, and value is swapped out,
                              * this is the type of the swapped out object. */
        int refcount;
        /* VM fields, this are only allocated if VM is active, otherwise the
         * object allocation function will just allocate
         * sizeof(redisObject) minus sizeof(redisObjectVM), so using
         * Redis without VM active will not have any overhead. */
        struct redisObjectVM vm;
    } robj;

As you can see there are a few fields about VM. The most important one is _storage_, that can be one of this values:

 * `REDIS_VM_MEMORY`: the associated value is in memory.
 * `REDIS_VM_SWAPPED`: the associated values is swapped, and the value entry of the hash table is just set to NULL.
 * `REDIS_VM_LOADING`: the value is swapped on disk, the entry is NULL, but there is a job to load the object from the swap to the memory (this field is only used when threaded VM is active).
 * `REDIS_VM_SWAPPING`: the value is in memory, the entry is a pointer to the actual Redis Object, but there is an I/O job in order to transfer this value to the swap file.

If an object is swapped on disk (`REDIS_VM_SWAPPED` or `REDIS_VM_LOADING`), how do we know where it is stored, what type it is, and so forth? That's simple: the _vtype_ field is set to the original type of the Redis object swapped, while the _vm_ field (that is a _redisObjectVM_ structure) holds information about the location of the object. This is the definition of this additional structure:

    /* The VM object structure */
    struct redisObjectVM {
        off_t page;         /* the page at which the object is stored on disk */
        off_t usedpages;    /* number of pages used on disk */
        time_t atime;       /* Last access time */
    } vm;

As you can see the structure contains the page at which the object is located in the swap file, the number of pages used, and the last access time of the object (this is very useful for the algorithm that select what object is a good candidate for swapping, as we want to transfer on disk objects that are rarely accessed).

As you can see, while all the other fields are using unused bytes in the old Redis Object structure (we had some free bit due to natural memory alignment concerns), the _vm_ field is new, and indeed uses additional memory. Should we pay such a memory cost even when VM is disabled? No! This is the code to create a new Redis Object:

    ... some code ...
            if (server.vm_enabled) {
                pthread_mutex_unlock(&server.obj_freelist_mutex);
                o = zmalloc(sizeof(*o));
            } else {
                o = zmalloc(sizeof(*o)-sizeof(struct redisObjectVM));
            }
    ... some code ...

As you can see if the VM system is not enabled we allocate just `sizeof(*o)-sizeof(struct redisObjectVM)` of memory. Given that the _vm_ field is the last in the object structure, and that this fields are never accessed if VM is disabled, we are safe and Redis without VM does not pay the memory overhead.

The Swap File
---

The next step in order to understand how the VM subsystem works is understanding how objects are stored inside the swap file. The good news is that's not some kind of special format, we just use the same format used to store the objects in .rdb files, that are the usual dump files produced by Redis using the `SAVE` command.

The swap file is composed of a given number of pages, where every page size is a given number of bytes. This parameters can be changed in redis.conf, since different Redis instances may work better with different values: it depends on the actual data you store inside it. The following are the default values:

    vm-page-size 32
    vm-pages 134217728

Redis takes a "bitmap" (an contiguous array of bits set to zero or one) in memory, every bit represent a page of the swap file on disk: if a given bit is set to 1, it represents a page that is already used (there is some Redis Object stored there), while if the corresponding bit is zero, the page is free.

Taking this bitmap (that will call the page table) in memory is a huge win in terms of performances, and the memory used is small: we just need 1 bit for every page on disk. For instance in the example below 134217728 pages of 32 bytes each (4GB swap file) is using just 16 MB of RAM for the page table.

Transferring objects from memory to swap
---

In order to transfer an object from memory to disk we need to perform the following steps (assuming non threaded VM, just a simple blocking approach):

 * Find how many pages are needed in order to store this object on the swap file. This is trivially accomplished just calling the function `rdbSavedObjectPages` that returns the number of pages used by an object on disk. Note that this function does not duplicate the .rdb saving code just to understand what will be the length *after* an object will be saved on disk, we use the trick of opening /dev/null and writing the object there, finally calling `ftello` in order check the amount of bytes required. What we do basically is to save the object on a virtual very fast file, that is, /dev/null.
 * Now that we know how many pages are required in the swap file, we need to find this number of contiguous free pages inside the swap file. This task is accomplished by the `vmFindContiguousPages` function. As you can guess this function may fail if the swap is full, or so fragmented that we can't easily find the required number of contiguous free pages. When this happens we just abort the swapping of the object, that will continue to live in memory.
 * Finally we can write the object on disk, at the specified position, just calling the function `vmWriteObjectOnSwap`.

As you can guess once the object was correctly written in the swap file, it is freed from memory, the storage field in the associated key is set to `REDIS_VM_SWAPPED`, and the used pages are marked as used in the page table.

Loading objects back in memory
---

Loading an object from swap to memory is simpler, as we already know where the object is located and how many pages it is using. We also know the type of the object (the loading functions are required to know this information, as there is no header or any other information about the object type on disk), but this is stored in the _vtype_ field of the associated key as already seen above.

Calling the function `vmLoadObject` passing the key object associated to the value object we want to load back is enough. The function will also take care of fixing the storage type of the key (that will be `REDIS_VM_MEMORY`), marking the pages as freed in the page table, and so forth.

The return value of the function is the loaded Redis Object itself, that we'll have to set again as value in the main hash table (instead of the NULL value we put in place of the object pointer when the value was originally swapped out).

How blocking VM works
---

Now we have all the building blocks in order to describe how the blocking VM works. First of all, an important detail about configuration. In order to enable blocking VM in Redis `server.vm_max_threads` must be set to zero.
We'll see later how this max number of threads info is used in the threaded VM, for now all it's needed to now is that Redis reverts to fully blocking VM when this is set to zero.

We also need to introduce another important VM parameter, that is, `server.vm_max_memory`. This parameter is very important as it is used in order to trigger swapping: Redis will try to swap objects only if it is using more memory than the max memory setting, otherwise there is no need to swap as we are matching the user requested memory usage.

Blocking VM swapping
---

Swapping of object from memory to disk happens in the cron function. This function used to be called every second, while in the recent Redis versions on git it is called every 100 milliseconds (that is, 10 times per second).
If this function detects we are out of memory, that is, the memory used is greater than the vm-max-memory setting, it starts transferring objects from memory to disk in a loop calling the function `vmSwapOneObect`. This function takes just one argument, if 0 it will swap objects in a blocking way, otherwise if it is 1, I/O threads are used. In the blocking scenario we just call it with zero as argument.

vmSwapOneObject acts performing the following steps:

 * The key space in inspected in order to find a good candidate for swapping (we'll see later what a good candidate for swapping is).
 * The associated value is transferred to disk, in a blocking way.
 * The key storage field is set to `REDIS_VM_SWAPPED`, while the _vm_ fields of the object are set to the right values (the page index where the object was swapped, and the number of pages used to swap it).
 * Finally the value object is freed and the value entry of the hash table is set to NULL.

The function is called again and again until one of the following happens: there is no way to swap more objects because either the swap file is full or nearly all the objects are already transferred on disk, or simply the memory usage is already under the vm-max-memory parameter.

What values to swap when we are out of memory?
---

Understanding what's a good candidate for swapping is not too hard. A few objects at random are sampled, and for each their _swappability_ is commuted as:

    swappability = age*log(size_in_memory)

The age is the number of seconds the key was not requested, while size_in_memory is a fast estimation of the amount of memory (in bytes) used by the object in memory. So we try to swap out objects that are rarely accessed, and we try to swap bigger objects over smaller one, but the latter is a less important factor (because of the logarithmic function used). This is because we don't want bigger objects to be swapped out and in too often as the bigger the object the more I/O and CPU is required in order to transfer it.

Blocking VM loading
---

What happens if an operation against a key associated with a swapped out object is requested? For instance Redis may just happen to process the following command:

    GET foo

If the value object of the `foo` key is swapped we need to load it back in memory before processing the operation. In Redis the key lookup process is centralized in the `lookupKeyRead` and `lookupKeyWrite` functions, this two functions are used in the implementation of all the Redis commands accessing the keyspace, so we have a single point in the code where to handle the loading of the key from the swap file to memory.

So this is what happens:

 * The user calls some command having as argument a swapped key
 * The command implementation calls the lookup function
 * The lookup function search for the key in the top level hash table. If the value associated with the requested key is swapped (we can see that checking the _storage_ field of the key object), we load it back in memory in a blocking way before to return to the user.

This is pretty straightforward, but things will get more _interesting_ with the threads. From the point of view of the blocking VM the only real problem is the saving of the dataset using another process, that is, handling `BGSAVE` and `BGREWRITEAOF` commands.

Background saving when VM is active
---

The default Redis way to persist on disk is to create .rdb files using a child process. Redis calls the fork() system call in order to create a child, that has the exact copy of the in memory dataset, since fork duplicates the whole program memory space (actually thanks to a technique called Copy on Write memory pages are shared between the parent and child process, so the fork() call will not require too much memory).

In the child process we have a copy of the dataset in a given point in the time. Other commands issued by clients will just be served by the parent process and will not modify the child data.

The child process will just store the whole dataset into the dump.rdb file and finally will exit. But what happens when the VM is active? Values can be swapped out so we don't have all the data in memory, and we need to access the swap file in order to retrieve the swapped values. While child process is saving the swap file is shared between the parent and child process, since:

* The parent process needs to access the swap file in order to load values back into memory if an operation against swapped out values are performed.
* The child process needs to access the swap file in order to retrieve the full dataset while saving the data set on disk.

In order to avoid problems while both the processes are accessing the same swap file we do a simple thing, that is, not allowing values to be swapped out in the parent process while a background saving is in progress. This way both the processes will access the swap file in read only. This approach has the problem that while the child process is saving no new values can be transferred on the swap file even if Redis is using more memory than the max memory parameters dictates. This is usually not a problem as the background saving will terminate in a short amount of time and if still needed a percentage of values will be swapped on disk ASAP.

An alternative to this scenario is to enable the Append Only File that will have this problem only when a log rewrite is performed using the `BGREWRITEAOF` command.

The problem with the blocking VM
---

The problem of blocking VM is that... it's blocking :)
This is not a problem when Redis is used in batch processing activities, but for real-time usage one of the good points of Redis is the low latency. The blocking VM will have bad latency behaviors as when a client is accessing a swapped out value, or when Redis needs to swap out values, no other clients will be served in the meantime.

Swapping out keys should happen in background. Similarly when a client is accessing a swapped out value other clients accessing in memory values should be served mostly as fast as when VM is disabled. Only the clients dealing with swapped out keys should be delayed.

All this limitations called for a non-blocking VM implementation.

Threaded VM
---

There are basically three main ways to turn the blocking VM into a non blocking one.
* 1: One way is obvious, and in my opinion, not a good idea at all, that is, turning Redis itself into a threaded server: if every request is served by a different thread automatically other clients don't need to wait for blocked ones. Redis is fast, exports atomic operations, has no locks, and is just 10k lines of code, *because* it is single threaded, so this was not an option for me.
* 2: Using non-blocking I/O against the swap file. After all you can think Redis already event-loop based, why don't just handle disk I/O in a non-blocking fashion? I also discarded this possibility because of two main reasons. One is that non blocking file operations, unlike sockets, are an incompatibility nightmare. It's not just like calling select, you need to use OS-specific things. The other problem is that the I/O is just one part of the time consumed to handle VM, another big part is the CPU used in order to encode/decode data to/from the swap file. This is I picked option three, that is...
* 3: Using I/O threads, that is, a pool of threads handling the swap I/O operations. This is what the Redis VM is using, so let's detail how this works.

I/O Threads
---

The threaded VM design goals where the following, in order of importance:

 * Simple implementation, little room for race conditions, simple locking, VM system more or less completely decoupled from the rest of Redis code.
 * Good performances, no locks for clients accessing values in memory.
 * Ability to decode/encode objects in the I/O threads.

The above goals resulted in an implementation where the Redis main thread (the one serving actual clients) and the I/O threads communicate using a queue of jobs, with a single mutex.
Basically when main thread requires some work done in the background by some I/O thread, it pushes an I/O job structure in the `server.io_newjobs` queue (that is, just a linked list). If there are no active I/O threads, one is started. At this point some I/O thread will process the I/O job, and the result of the processing is pushed in the `server.io_processed` queue. The I/O thread will send a byte using an UNIX pipe to the main thread in order to signal that a new job was processed and the result is ready to be processed.

This is how the `iojob` structure looks like:

    typedef struct iojob {
        int type;   /* Request type, REDIS_IOJOB_* */
        redisDb *db;/* Redis database */
        robj *key;  /* This I/O request is about swapping this key */
        robj *val;  /* the value to swap for REDIS_IOREQ_*_SWAP, otherwise this
                     * field is populated by the I/O thread for REDIS_IOREQ_LOAD. */
        off_t page; /* Swap page where to read/write the object */
        off_t pages; /* Swap pages needed to save object. PREPARE_SWAP return val */
        int canceled; /* True if this command was canceled by blocking side of VM */
        pthread_t thread; /* ID of the thread processing this entry */
    } iojob;

There are just three type of jobs that an I/O thread can perform (the type is specified by the `type` field of the structure):

* `REDIS_IOJOB_LOAD`: load the value associated to a given key from swap to memory. The object offset inside the swap file is `page`, the object type is `key->vtype`. The result of this operation will populate the `val` field of the structure.
* `REDIS_IOJOB_PREPARE_SWAP`: compute the number of pages needed in order to save the object pointed by `val` into the swap. The result of this operation will populate the `pages` field.
* `REDIS_IOJOB_DO_SWAP`: Transfer the object pointed by `val` to the swap file, at page offset `page`.

The main thread delegates just the above three tasks. All the rest is handled by the I/O thread itself, for instance finding a suitable range of free pages in the swap file page table (that is a fast operation), deciding what object to swap, altering the storage field of a Redis object to reflect the current state of a value.

Non blocking VM as probabilistic enhancement of blocking VM
---

So now we have a way to request background jobs dealing with slow VM operations. How to add this to the mix of the rest of the work done by the main thread? While blocking VM was aware that an object was swapped out just when the object was looked up, this is too late for us: in C it is not trivial to start a background job in the middle of the command, leave the function, and re-enter in the same point the computation when the I/O thread finished what we requested (that is, no co-routines or continuations or alike).

Fortunately there was a much, much simpler way to do this. And we love simple things: basically consider the VM implementation a blocking one, but add an optimization (using non the no blocking VM operations we are able to perform) to make the blocking *very* unlikely.

This is what we do:

 * Every time a client sends us a command, *before* the command is executed, we examine the argument vector of the command in search for swapped keys. After all we know for every command what arguments are keys, as the Redis command format is pretty simple.
 * If we detect that at least a key in the requested command is swapped on disk, we block the client instead of really issuing the command. For every swapped value associated to a requested key, an I/O job is created, in order to bring the values back in memory. The main thread continues the execution of the event loop, without caring about the blocked client.
 * In the meanwhile, I/O threads are loading values in memory. Every time an I/O thread finished loading a value, it sends a byte to the main thread using an UNIX pipe. The pipe file descriptor has a readable event associated in the main thread event loop, that is the function `vmThreadedIOCompletedJob`. If this function detects that all the values needed for a blocked client were loaded, the client is restarted and the original command called.

So you can think of this as a blocked VM that almost always happen to have the right keys in memory, since we pause clients that are going to issue commands about swapped out values until this values are loaded.

If the function checking what argument is a key fails in some way, there is no problem: the lookup function will see that a given key is associated to a swapped out value and will block loading it. So our non blocking VM reverts to a blocking one when it is not possible to anticipate what keys are touched.

For instance in the case of the `SORT` command used together with the `GET` or `BY` options, it is not trivial to know beforehand what keys will be requested, so at least in the first implementation, `SORT BY/GET` resorts to the blocking VM implementation.

Blocking clients on swapped keys
---

How to block clients? To suspend a client in an event-loop based server is pretty trivial. All we do is canceling its read handler. Sometimes we do something different (for instance for BLPOP) that is just marking the client as blocked, but not processing new data (just accumulating the new data into input buffers).

Aborting I/O jobs
---

There is something hard to solve about the interactions between our blocking and non blocking VM, that is, what happens if a blocking operation starts about a key that is also "interested" by a non blocking operation at the same time?

For instance while SORT BY is executed, a few keys are being loaded in a blocking manner by the sort command. At the same time, another client may request the same keys with a simple _GET key_ command, that will trigger the creation of an I/O job to load the key in background.

The only simple way to deal with this problem is to be able to kill I/O jobs in the main thread, so that if a key that we want to load or swap in a blocking way is in the `REDIS_VM_LOADING` or `REDIS_VM_SWAPPING` state (that is, there is an I/O job about this key), we can just kill the I/O job about this key, and go ahead with the blocking operation we want to perform.

This is not as trivial as it is. In a given moment an I/O job can be in one of the following three queues:

 * server.io_newjobs: the job was already queued but no thread is handling it.
 * server.io_processing: the job is being processed by an I/O thread.
 * server.io_processed: the job was already processed.
The function able to kill an I/O job is `vmCancelThreadedIOJob`, and this is what it does:
 * If the job is in the newjobs queue, that's simple, removing the iojob structure from the queue is enough as no thread is still executing any operation.
 * If the job is in the processing queue, a thread is messing with our job (and possibly with the associated object!). The only thing we can do is waiting for the item to move to the next queue in a *blocking way*. Fortunately this condition happens very rarely so it's not a performance problem.
 * If the job is in the processed queue, we just mark it as _canceled_ marking setting the `canceled` field to 1 in the iojob structure. The function processing completed jobs will just ignored and free the job instead of really processing it.

Questions?
---

This document is in no way complete, the only way to get the whole picture is reading the source code, but it should be a good introduction in order to make the code review / understanding a lot simpler.

Something is not clear about this page? Please leave a comment and I'll try to address the issue possibly integrating the answer in this document.
