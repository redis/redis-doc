# Threaded I/O
## Introduction
In order to keep it simple and reliable, Redis is mostly single-threaded. The implementation of parallel query execution might set an entry barrier for every new feature. However, there are certain threaded operations such as UNLINK, slow I/O accesses and other things that are performed on side threads.

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
By default, Redis uses I/O threads on the write system call only. If you want to use it on the read  system call, you have to enable this option as well. Usually, threaded reads don't help much.

## High-Level Architecture
The main idea of this feature is to postpone the read and write action and accumulate those events to the next event loop cycle. So that we have multiple events waiting to be handled and use I/O threads to deal with them.

For example, when Redis has done executing a command from client `A` and got the reply content, instead of writing it to the client connection synchronously, Redis save it to a **pending list**, which contains other `client-reply content` pairs as well, and wait for better timing to do the write action (next event loop cycle period). In the previous version, Redis read this pending list sequentially, and write the reply content to the client one by one using the main thread. In Redis 6, it changed into writing with multiple I/O threads parallelly.

For the reading action, when a command/message is sent to the Redis server, it's described as a file event, which will trigger Redis to read from the client connection directly. After that, Redis continues to decode/analyze/execute the command/message and get the result, added it to the write pending list as we discussed above, and handles the next happened event until no more available file event or time event happened. So in this case, the `io-threads-do-reads` option allows you to stop reading client connections when the event arrived, collect them to a **pending list** as well, and postpone the read action to the next cycle period using multiple I/O threads. When reads are done, Redis use the main thread to execute the client command one by one.

I/O threads are only activated when the main thread gets the read/write pending list prepared. The workflow can be described as below:

1. main thread prepare the pending list for read
2. I/O threads read from the connections parallelly
3. main thread executes command one by one
4. main thread prepare the pending list for write
5. I/O threads write reply content to the connections parallelly


## Low-Level Design
### Where is the pending list
We will focus on a few variables to understand how Redis prepare those pending list.

When the Redis server is running, it's described as a `server` object in memory. The `server` object has attributes named `clients_pending_write` and `clients_pending_read` (We will call it **client queue** in the following doc), which are list type with their item value points to the `client` object, describing the Redis client.

main thread appends the `client` object to the **client queue for read** when file event from one client happened. So this queue will accumulate many `client` objects during one `aeMain` loop period. Same for the writing procedure, after the command execution, Redis append the `client` object who called this command to the **client queue for write**.
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
So when the client query for read is ready (same for the write), we need to dispatch them to the I/O threads which are waiting.

Redis prepared a global variable `io_threads_list` to store the task. `io_threads_list` is a list type variable with thread number length (configured by `io-threads n`). Its item value is a list as well which each sub-item stores the `client` object pointer.

Each `io_threads_list` item represents the task list (client list) the corresponding thread should handle. Redis dispatch the pending clients using **Round-Robin** algorithm. So when we configured **4 I/O threads** (thread 0 to thread 3), and have **7 clients** (client 0 to client6) in the client queue, they will be dispatched like:
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

Each thread can iterate over the clients they should read, do read operation, and store the result to the query buffer. The main thread will also handle part of the pending tasks after dispatching. In this example, thread 0, which is the main thread, will read through client 0 and then client 4.

### Blocking and Locking
There will be a racing condition if the I/O thread keeps monitoring and editing the `io_threads_list`. So Redis prepared another atomic variable `io_threads_pending` (We will call it **remaining task counter** in the following doc).

The **remaining task counter** is a thread number length list and stores an integer value **representing the number of the remaining task that the corresponding thread should handle**. When the main thread finished dispatching task to `io_threads_list`, it set each **task counter** item to the actual task count.

The I/O threads will stay in a **busy loop** and checking if its **task counter item** has become positive. Then begin to read/write through the clients in its `io_threads_list` item. Once I/O threads finish their job, they will empty the list in `io_threads_list` item, and set their task counter value to 0. The main thread will know all I/O read/write tasks are done when `sum(task counter)` decreases to 0.

Since I/O threads will keep spinning and check the task counter value, when the Redis server is running under a low workload, it will use a mutex lock to stop the I/O threads to save resources. Redis inited a list of mutex lock `io_threads_mutex` during I/O threads' initialization. When the length of **client queue for write** meets a certain condition (lesser than `2 * io_threads_num`), Redis main thread will acquire the mutex lock for all I/O threads. The I/O threads exit spinning periodically and check if they could acquire mutex lock, and stop at this position when the lock is owned by the main thread.

## Limitations
The I/O threads won't work (won't postpone read/write) when:
- Server under low workload conditions.
- `io-threads` not configured or set to 1.
- The client is marked as a master/slave role.
- The client has added to the pending list already.
- Server running with TLS.

And remember `io-threads-do-reads` control the I/O threads' behavior in the reading procedure.
