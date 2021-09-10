Redis Event Library
===

Redis implements its own event library. The event library is implemented in `ae.c`.

The best way to understand how the Redis event library works is to understand how Redis uses it.

Event Loop Initialization
---

`initServer` function defined in `redis.c` initializes the numerous fields of the `redisServer` structure variable. One such field is the Redis event loop `el`:

    aeEventLoop *el

`initServer` initializes `server.el` field by calling `aeCreateEventLoop` defined in `ae.c`. The definition of `aeEventLoop` is below:

    typedef struct aeEventLoop
    {
        int maxfd;
        long long timeEventNextId;
        aeFileEvent events[AE_SETSIZE]; /* Registered events */
        aeFiredEvent fired[AE_SETSIZE]; /* Fired events */
        aeTimeEvent *timeEventHead;
        int stop;
        void *apidata; /* This is used for polling API specific data */
        aeBeforeSleepProc *beforesleep;
    } aeEventLoop;

`aeCreateEventLoop`
---

`aeCreateEventLoop` first `malloc`s `aeEventLoop` structure then calls `ae_epoll.c:aeApiCreate`.

`aeApiCreate` `malloc`s `aeApiState` that has two fields - `epfd` that holds the `epoll` file descriptor returned by a call from [`epoll_create`](http://man.cx/epoll_create%282%29) and `events` that is of type `struct epoll_event` define by the Linux `epoll` library. The use of the `events` field will be  described later.

Next is `ae.c:aeCreateTimeEvent`. But before that `initServer` call `anet.c:anetTcpServer` that creates and returns a _listening descriptor_. The descriptor listens on *port 6379* by default. The returned  _listening descriptor_ is stored in `server.fd` field.

`aeCreateTimeEvent`
---

`aeCreateTimeEvent` accepts the following as parameters:

  * `eventLoop`: This is `server.el` in `redis.c`
  * milliseconds: The number of milliseconds from the current time after which the timer expires.
  * `proc`: Function pointer. Stores the address of the function that has to be called after the timer expires.
  * `clientData`: Mostly `NULL`.
  * `finalizerProc`: Pointer to the function that has to be called before the timed event is removed from the list of timed events.

`initServer` calls `aeCreateTimeEvent` to add a timed event to `timeEventHead` field of `server.el`. `timeEventHead` is a pointer to a list of such timed events. The call to `aeCreateTimeEvent` from `redis.c:initServer` function is given below:

    aeCreateTimeEvent(server.el /*eventLoop*/, 1 /*milliseconds*/, serverCron /*proc*/, NULL /*clientData*/, NULL /*finalizerProc*/);

`redis.c:serverCron` performs many operations that helps keep Redis running properly.

`aeCreateFileEvent`
---

The essence of `aeCreateFileEvent` function is to execute [`epoll_ctl`](http://man.cx/epoll_ctl) system call which adds a watch for `EPOLLIN` event on the _listening descriptor_ create by `anetTcpServer` and associate it with the `epoll` descriptor created by a call to `aeCreateEventLoop`.

Following is an explanation of what precisely `aeCreateFileEvent` does when called from `redis.c:initServer`.

`initServer` passes the following arguments to `aeCreateFileEvent`:

  * `server.el`: The event loop created by `aeCreateEventLoop`. The `epoll` descriptor is got from `server.el`.
  * `server.fd`: The _listening descriptor_ that also serves as an index to access the relevant file event structure from the `eventLoop->events` table and store extra information like the callback function.
  * `AE_READABLE`: Signifies that `server.fd` has to be watched for `EPOLLIN` event.
  * `acceptHandler`: The function that has to be executed when the event being watched for is ready. This function pointer is stored in `eventLoop->events[server.fd]->rfileProc`.

This completes the initialization of Redis event loop.

Event Loop Processing
---

`ae.c:aeMain` called from `redis.c:main` does the job of processing the event loop that is initialized in the previous phase.

`ae.c:aeMain` calls `ae.c:aeProcessEvents` in a while loop that processes pending time and file events.

`aeProcessEvents`
---

`ae.c:aeProcessEvents` looks for the time event that will be pending in the smallest amount of time by calling `ae.c:aeSearchNearestTimer` on the event loop. In our case there is only one timer event in the event loop that was created by `ae.c:aeCreateTimeEvent`.

Remember, that the timer event created by `aeCreateTimeEvent` has probably elapsed by now because it had an expiry time of one millisecond. Since the timer has already expired, the seconds and microseconds fields of the `tvp` `timeval` structure variable is initialized to zero.

The `tvp` structure variable along with the event loop variable is passed to `ae_epoll.c:aeApiPoll`.

`aeApiPoll` functions does an [`epoll_wait`](http://man.cx/epoll_wait) on the `epoll` descriptor and populates the `eventLoop->fired` table with the details:

  * `fd`: The descriptor that is now ready to do a read/write operation depending on the mask value.
  * `mask`: The read/write event that can now be performed on the corresponding descriptor.

`aeApiPoll` returns the number of such file events ready for operation. Now to put things in context, if any client has requested for a connection then `aeApiPoll` would have noticed it and populated the `eventLoop->fired` table with an entry of the descriptor being the _listening descriptor_ and mask being `AE_READABLE`.

Now, `aeProcessEvents` calls the `redis.c:acceptHandler` registered as the callback. `acceptHandler` executes [accept](http://man.cx/accept) on the _listening descriptor_ returning a _connected descriptor_ with the client. `redis.c:createClient` adds a file event on the _connected descriptor_ through a call to `ae.c:aeCreateFileEvent` like below:

    if (aeCreateFileEvent(server.el, c->fd, AE_READABLE,
        readQueryFromClient, c) == AE_ERR) {
        freeClient(c);
        return NULL;
    }

`c` is the `redisClient` structure variable and `c->fd` is the connected descriptor.

Next the `ae.c:aeProcessEvent` calls `ae.c:processTimeEvents`

`processTimeEvents`
---

`ae.processTimeEvents` iterates over list of time events starting at `eventLoop->timeEventHead`.

For every timed event that has elapsed `processTimeEvents` calls the registered callback. In this case it calls the only timed event callback registered, that is, `redis.c:serverCron`. The callback returns the time in milliseconds after which the callback must be called again. This change is recorded via a call to `ae.c:aeAddMilliSeconds` and will be handled on the next iteration of `ae.c:aeMain` while loop.

That's all.
