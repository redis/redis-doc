# Threaded I/O
## Introduction
Redis is mostly single-threaded, however there are certain threaded operations such as UNLINK, slow I/O accesses and other things that are performed on side threads.

Now it is also possible to handle Redis clients' socket reads and writes in different I/O threads. Since especially writing is so slow, normally Redis users use pipelining in order to speed up the Redis performances per core, and spawn multiple instances in order to scale more. Using I/O threads it is possible to easily speedup two times Redis without resorting to pipelining nor sharding of the instance.

## Configuration
We have two options to control how I/O threads perform.
```
io-threads 4
```
The `io-threads` option control how many threads you want to use on reading/writing client connections.
- 1 or not configured: Use single thread like what we have in the older version.
- n (n >= 2): Use n threads(1 main thread & n-1 I/O threads) to handle network reads/writes.

```
io-threads-do-reads yes
```
By default, Redis uses I/O threads on the writing process only. If you want to use it on the reading process, you have to enable this option as well. Usually, threaded reads don't help much.

## High-Level Architecture
The main idea of this feature is to postpone the read and write process and accumulate those events to the next event loop cycle. So that we have multiple events waiting to be handled and use I/O threads to deal with them.

For example, when Redis has done processing a command from client `A` and got the reply content, instead of writing it to the client connection synchronously, Redis save it to a **pending list**, which contains other `client-reply content` pairs as well, and wait for better timing to do the write action (next event loop cycle period). In the previous version, Redis read this pending list sequentially, and write the reply content to the client one by one using the main thread. In Redis 6, it changed into writing with multiple I/O threads parallelly.

For the reading process, when a command/message is sent to the Redis server, it's described as a file event, which will trigger Redis to read from the client connection directly. After the reading process, Redis continues to decode/analysis/execute the command/message and get the result, added it to the write pending list as we discussed above, and handle the next happened event until no more available file event or time event happened. So in this case, the `io-threads-do-reads` option allows you to stop reading client connection when the event arrived, collect them to a **pending list** as well, and postpone the read action to the next cycle period using multiple I/O threads. When reads are done, Redis use the main thread to execute the client command one by one.

I/O threads are only activated when the main thread gets the read/write pending list prepared. The workflow can be described as below:
```
main thread prepare the pending list for read -> I/O threads read from the connections -> 
main thread execute command one by one -> main thread prepare the pending list for write -> 
I/O threads write reply content to the connections
```

## Low-Level Design
### Where is the pending list
We will focus on a few variables to understand how Redis prepare those pending list.

When the Redis server is running, it's described as a `server` object in memory. The `server` object has attributes named `clients_pending_write` and `clients_pending_read`, which are list type with their item value points to the `client` object, which describes the Redis client.

main thread append the `client` object to `server.clients_pending_read` when file event from one client happened. So this list type attribute will accumulate many `client` objects during one `aeMain` loop period. Same for the `server.clients_pending_read`, after the command execution, Redis append the `client` object who called this command to the `clients_pending_read` list.
```
+-----------------------------+
|      redisServer obj        |
+-----------------------------+
| attr: pid                   |
+-----------------------------+
| attr: port                  |
+-----------------------------+
| ...                         | 
+-----------------------------+        +-----------+-----------+-----------+---------+---------+
| attr: clients_pending_read  | -----> | *client A | *client B | *client C |   ...   |   ...   |
+-----------------------------+        +-----------+-----------+-----------+---------+---------+
| attr: clients_pending_write |              |
+-----------------------------+              |
| ...                         |              |
+-----------------------------+              |
                                             |      +-----------------+
                                             +----> | redisClient obj |
                                                    +-----------------+
                                                    | attr: pid       |
                                                    +-----------------+
                                                    | attr: *conn     |
                                                    +-----------------+
                                                    | attr: querybuf  |
                                                    +-----------------+
                                                    | attr: buf       |
                                                    +-----------------+
                                                    | ...             |
                                                    +-----------------+


```

### Dispatch read/write tasks to I/O threads
So when the `server.clients_pending_read` is ready (same for the writing process), we need to dispatch them to the I/O threads which are waiting.

Redis prepared a global variable `io_threads_list` to store the task. `io_threads_list` is a list type variable with thread number length (configured by `io-threads n`). Its item value is a list as well which each sub-item stores the `client` object pointer.

`io_threads_list[i]` represents the task list (client list) the i-th thread should handle. Redis dispatch the pending client using **Round-Robin** algorithm. So when we configured **4 I/O threads** (thread 0 to thread 3), and have **7 clients** (client 0 to client6) in `server.clients_pending_read` list, they will be dispatched like:
```
io_threads_list
+---------------+------------+------------+------------+
|   thread 0    |  thread 1  |  thread 2  |  thread 3  |
| (main thread) |(I/O thread)|(I/O thread)|(I/O thread)|
+---------------+------------+------------+------------+
      \/              \/           \/            \/        
      \/              \/           \/            \/             
      \/              \/           \/            \/        
  +----------+   +----------+  +----------+  +----------+
  | client 0 |   | client 1 |  | client 2 |  | client 3 |
  +----------+   +----------+  +----------+  +----------+
  | client 4 |   | client 5 |  | client 6 |
  +----------+   +----------+  +----------+

```

Each thread can iterate over the clients they should read, do read action, and store the result to `client.querybuf` attribute. The main thread will also handle part of the pending tasks after dispatching. In this example, thread 0, which is the main thread, will read through client 0 and then client 4, thread 1 will handle client 1 and client 5, and so on.

### Blocking and Locking
There will be a racing condition if the I/O thread keeps monitoring and editing the `io_threads_list[i]` list. So Redis prepared another global variable named `io_threads_pending`. It's a thread number length list and stores an integer value representing the number of the remaining task that thread i should handle.

When the main thread finished dispatching task to `io_threads_list`, it set `io_threads_pending[i]` to the actual task count.

The I/O threads will stay in a `for (int j = 0; j < 1000000; j++)` loop and checking if `io_threads_pending[id] != 0`. So when the value changed to an positive integer, thread i begin to read/write through the client in `io_threads_list[i]`. 

Once I/O threads finish their job, they will empty the list in `io_threads_list[i]`, and set `io_threads_pending[i]` to 0.

When the Redis server is running under a low workload, it will use a mutex lock to stop the I/O threads from keeping looping and checking the `io_threads_pending[i]` value. 

When I/O threads are inited, Redis also inited a list of mutex `io_threads_mutex`, `io_threads_mutex[i]` representing the mutex lock for the thread i.

When `server.clients_pending_write` length is lower than 2 * io_threads_num we've configured, Redis will stop the I/O threads by executing `pthread_mutex_lock(&io_threads_mutex[i])`. So when the main thread acquired the i-th mutex lock successfully, the corresponding I/O thread will be blocked on acquiring the same mutex lock. 

The I/O thread will execute those codes in their `while` loop. So in each loop period, the main thread will have a chance to stop them by locking:
```
...
    while(1)
        ...
        pthread_mutex_lock(&io_threads_mutex[id]);
        pthread_mutex_unlock(&io_threads_mutex[id]);
        ...
...
```

## Limitations
The I/O threads won't work (won't postpone read/write) when:
- Server under low workload conditions.
- `io-threads` not configured or set to 1.
- The client is marked as a master/slave role.
- The client has added to the pending list already.

And remember `io-threads-do-reads` control the I/O threads' behavior in the read process.
