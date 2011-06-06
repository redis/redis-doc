A case study: Design and implementation of a simple Twitter clone using only the Redis key-value store as database and PHP
===

In this article I'll explain the design and the implementation of a [simple clone of Twitter](http://retwis.antirez.com) written using PHP and Redis as only database. The programming community uses to look at key-value stores like special databases that can't be used as drop in replacement for a relational database for the development of web applications. This article will try to prove the contrary.

Our Twitter clone, [called Retwis](http://retwis.antirez.com), is structurally simple, has very good performance, and can be distributed among N web servers and M Redis servers with very little effort. You can find the source code [here](http://code.google.com/p/redis/downloads/list).

We use PHP for the example since it can be read by everybody. The same (or... much better) results can be obtained using Ruby, Python, Erlang, and so on.

**Note:** [Retwis-RB](http://retwisrb.danlucraft.com/) is a port of Retwis to
Ruby and Sinatra written by Daniel Lucraft! With full source code included of
course, the Git repository is linked in the footer of the web page. The rest
of this article targets PHP, but Ruby programmers can also check the other
source code, it conceptually very similar.

**Note:** [Retwis-J](http://retwisj.cloudfoundry.com/) is a port of Retwis to
Java, using the Spring Data Framework, written by Costin Leau. The source code
can be found on
[GitHub](https://github.com/SpringSource/spring-data-keyvalue-examples) and
there is comprehensive documentation available at
[springsource.org](http://j.mp/eo6z6I).

Key-value stores basics
---
The essence of a key-value store is the ability to store some data, called _value_, inside a key. This data can later be retrieved only if we know the exact key used to store it. There is no way to search something by value. In a sense, it is like a very large hash/dictionary, but it is persistent, i.e. when your application ends, the data doesn't go away. So for example I can use the command SET to store the value *bar* at key *foo*:

    SET foo bar

Redis will store our data permanently, so we can later ask for "_What is the value stored at key foo?_" and Redis will reply with *bar*:

    GET foo => bar

Other common operations provided by key-value stores are DEL used to delete a given key, and the associated value, SET-if-not-exists (called SETNX on Redis) that sets a key only if it does not already exist, and INCR that is able to atomically increment a number stored at a given key:

    SET foo 10
    INCR foo => 11
    INCR foo => 12
    INCR foo => 13

Atomic operations
---

So far it should be pretty simple, but there is something special about INCR. Think about this, why to provide such an operation if we can do it ourselves with a bit of code? After all it is as simple as:

    x = GET foo
    x = x + 1
    SET foo x

The problem is that doing the increment this way will work as long as there is only a client working with the value _x_ at a time. See what happens if two computers are accessing this data at the same time:

    x = GET foo (yields 10)
    y = GET foo (yields 10)
    x = x + 1 (x is now 11)
    y = y + 1 (y is now 11)
    SET foo x (foo is now 11)
    SET foo y (foo is now 11)

Something is wrong with that! We incremented the value two times, but instead to go from 10 to 12 our key holds 11. This is because the INCR operation done with `GET / increment / SET` *is not an atomic operation*. Instead the INCR provided by Redis, Memcached, ..., are atomic implementations, the server will take care to protect the get-increment-set for all the time needed to complete in order to prevent simultaneous accesses.

What makes Redis different from other key-value stores is that it provides more operations similar to INCR that can be used together to model complex problems. This is why you can use Redis to write whole web applications without using an SQL database and without going crazy.

Beyond key-value stores
---
In this section we will see what Redis features we need to build our Twitter clone. The first thing to know is that Redis values can be more than strings. Redis supports Lists and Sets as values, and there are atomic operations to operate against this more advanced values so we are safe even with multiple accesses against the same key. Let's start from Lists:

    LPUSH mylist a (now mylist holds one element list 'a')
    LPUSH mylist b (now mylist holds 'b,a')
    LPUSH mylist c (now mylist holds 'c,b,a')

LPUSH means _Left Push_, that is, add an element to the left (or to the head) of the list stored at _mylist_. If the key _mylist_ does not exist it is automatically created by Redis as an empty list before the PUSH operation. As you can imagine, there is also the RPUSH operation that adds the element on the right of the list (on the tail).

This is very useful for our Twitter clone. Updates of users can be stored into a list stored at `username:updates` for instance. There are operations to get data or information from Lists of course. For instance LRANGE returns a range of the list, or the whole list.

    LRANGE mylist 0 1 => c,b

LRANGE uses zero-based indexes, that is the first element is 0, the second 1, and so on. The command arguments are `LRANGE key first-index last-index`. The _last index_ argument can be negative, with a special meaning: -1 is the last element of the list, -2 the penultimate, and so on. So in order to get the whole list we can use:

    LRANGE mylist 0 -1 => c,b,a

Other important operations are LLEN that returns the length of the list, and LTRIM that is like LRANGE but instead of returning the specified range *trims* the list, so it is like _Get range from mylist, Set this range as new value_ but atomic. We will use only this List operations, but make sure to check the [Redis documentation](http://code.google.com/p/redis/wiki/README) to discover all the List operations supported by Redis.

The set data type
---

There is more than Lists, Redis also supports Sets, that are unsorted collection of elements. It is possible to add, remove, and test for existence of members, and perform intersection between different Sets. Of course it is possible to ask for the list or the number of elements of a Set. Some example will make it more clear. Keep in mind that SADD is the _add to set_ operation, SREM is the _remove from set_ operation, _sismember_ is the _test if it is a member_ operation, and SINTER is _perform intersection_ operation. Other operations are SCARD that is used to get the cardinality (the number of elements) of a Set, and SMEMBERS that will return all the members of a Set.

    SADD myset a
    SADD myset b
    SADD myset foo
    SADD myset bar
    SCARD myset => 4
    SMEMBERS myset => bar,a,foo,b

Note that SMEMBERS does not return the elements in the same order we added them, since Sets are *unsorted* collections of elements. When you want to store the order it is better to use Lists instead. Some more operations against Sets:

    SADD mynewset b
    SADD mynewset foo
    SADD mynewset hello
    SINTER myset mynewset => foo,b

SINTER can return the intersection between Sets but it is not limited to two sets, you may ask for intersection of 4,5 or 10000 Sets. Finally let's check how SISMEMBER works:

    SISMEMBER myset foo => 1
    SISMEMBER myset notamember => 0

Okay, I think we are ready to start coding!

Prerequisites
---

If you didn't download it already please grab the [source code of Retwis](http://code.google.com/p/redis/downloads/list). It's a simple tar.gz file with a few of PHP files inside. The implementation is very simple. You will find the PHP library client inside (redis.php) that is used to talk with the Redis server from PHP. This library was written by [Ludovico Magnocavallo](http://qix.it) and you are free to reuse this in your own projects, but for updated version of the library please download the Redis distribution. (Note: there are now better PHP libraries available, check our [clients page](/clients).

Another thing you probably want is a working Redis server. Just get the source, compile with make, and run with ./redis-server and you are done. No configuration is required at all in order to play with it or to run Retwis in your computer.

Data layout
---

Working with a relational database this is the stage were the database layout should be produced in form of tables, indexes, and so on. We don't have tables, so what should be designed? We need to identify what keys are needed to represent our objects and what kind of values this keys need to hold.

Let's start from Users. We need to represent this users of course, with the username, userid, password, followers and following users, and so on. The first question is, what should identify an user inside our system? The username can be a good idea since it is unique, but it is also too big, and we want to stay low on memory. So like if our DB was a relational one we can associate an unique ID to every user. Every other reference to this user will be done by id. That's very simple to do, because we have our atomic INCR operation! When we create a new user we can do something like this, assuming the user is called "antirez":

    INCR global:nextUserId => 1000
    SET uid:1000:username antirez
    SET uid:1000:password p1pp0

We use the _global:nextUserId_ key in order to always get an unique ID for every new user. Then we use this unique ID to populate all the other keys holding our user data. *This is a Design Pattern* with key-values stores! Keep it in mind.
Besides the fields already defined, we need some more stuff in order to fully define an User. For example sometimes it can be useful to be able to get the user ID from the username, so we set this key too:

    SET username:antirez:uid 1000

This may appear strange at first, but remember that we are only able to access data by key! It's not possible to tell Redis to return the key that holds a specific value. This is also *our strength*, this new paradigm is forcing us to organize the data so that everything is accessible by _primary key_, speaking with relational DBs language.

Following, followers and updates
---

There is another central need in our system. Every user has followers users and following users. We have a perfect data structure for this work! That is... Sets. So let's add this two new fields to our schema:

    uid:1000:followers => Set of uids of all the followers users
    uid:1000:following => Set of uids of all the following users

Another important thing we need is a place were we can add the updates to display in the user home page. We'll need to access this data in chronological order later, from the most recent update to the older ones, so the perfect kind of Value for this work is a List. Basically every new update will be LPUSHed in the user updates key, and thanks to LRANGE we can implement pagination and so on. Note that we use the words _updates_ and _posts_ interchangeably, since updates are actually "little posts" in some way.

    uid:1000:posts => a List of post ids, every new post is LPUSHed here.

Authentication
---

OK, we have more or less everything about the user, but authentication. We'll handle authentication in a simple but robust way: we don't want to use PHP sessions or other things like this, our system must be ready in order to be distributed among different servers, so we'll take the whole state in our Redis database. So all we need is a random string to set as the cookie of an authenticated user, and a key that will tell us what is the user ID of the client holding such a random string. We need two keys in order to make this thing working in a robust way:

    SET uid:1000:auth fea5e81ac8ca77622bed1c2132a021f9
    SET auth:fea5e81ac8ca77622bed1c2132a021f9 1000

In order to authenticate an user we'll do this simple work (`login.php`):
 * Get the username and password via the login form
 * Check if the username:`<username>`:uid key actually exists
 * If it exists we have the user id, (i.e. 1000)
 * Check if uid:1000:password matches, if not, error message
 * Ok authenticated! Set "fea5e81ac8ca77622bed1c2132a021f9" (the value of uid:1000:auth) as "auth" cookie

This is the actual code:

    include("retwis.php");

    # Form sanity checks
    if (!gt("username") || !gt("password"))
        goback("You need to enter both username and password to login.");

    # The form is OK, check if the username is available
    $username = gt("username");
    $password = gt("password");
    $r = redisLink();
    $userid = $r->get("username:$username:id");
    if (!$userid)
        goback("Wrong username or password");
    $realpassword = $r->get("uid:$userid:password");
    if ($realpassword != $password)
        goback("Wrong useranme or password");

    # Username / password OK, set the cookie and redirect to index.php
    $authsecret = $r->get("uid:$userid:auth");
    setcookie("auth",$authsecret,time()+3600*24*365);
    header("Location: index.php");

This happens every time the users log in, but we also need a function isLoggedIn in order to check if a given user is already authenticated or not. These are the logical steps preformed by the `isLoggedIn` function:
 * Get the "auth" cookie from the user. If there is no cookie, the user is not logged in, of course. Let's call the value of this cookie `<authcookie>`
 * Check if auth:`<authcookie>` exists, and what the value (the user id) is (1000 in the example).
 * In order to be sure check that uid:1000:auth matches.
 * OK the user is authenticated, and we loaded a bit of information in the $User global variable.

The code is simpler than the description, possibly:

    function isLoggedIn() {
        global $User, $_COOKIE;

        if (isset($User)) return true;

        if (isset($_COOKIE['auth'])) {
            $r = redisLink();
            $authcookie = $_COOKIE['auth'];
            if ($userid = $r->get("auth:$authcookie")) {
                if ($r->get("uid:$userid:auth") != $authcookie) return false;
                loadUserInfo($userid);
                return true;
            }
        }
        return false;
    }

    function loadUserInfo($userid) {
        global $User;

        $r = redisLink();
        $User['id'] = $userid;
        $User['username'] = $r->get("uid:$userid:username");
        return true;
    }

`loadUserInfo` as separated function is an overkill for our application, but it's a good template for a complex application. The only thing it's missing from all the authentication is the logout. What we do on logout? That's simple, we'll just change the random string in uid:1000:auth, remove the old auth:`<oldauthstring>` and add a new auth:`<newauthstring>`.

*Important:* the logout procedure explains why we don't just authenticate the user after the lookup of auth:`<randomstring>`, but double check it against uid:1000:auth. The true authentication string is the latter, the auth:`<randomstring>` is just an authentication key that may even be volatile, or if there are bugs in the program or a script gets interrupted we may even end with multiple auth:`<something>` keys pointing to the same user id. The logout code is the following (logout.php):

    include("retwis.php");

    if (!isLoggedIn()) {
        header("Location: index.php");
        exit;
    }

    $r = redisLink();
    $newauthsecret = getrand();
    $userid = $User['id'];
    $oldauthsecret = $r->get("uid:$userid:auth");

    $r->set("uid:$userid:auth",$newauthsecret);
    $r->set("auth:$newauthsecret",$userid);
    $r->delete("auth:$oldauthsecret");

    header("Location: index.php");

That is just what we described and should be simple to understand.

Updates
---

Updates, also known as posts, are even simpler. In order to create a new post on the database we do something like this:

    INCR global:nextPostId => 10343
    SET post:10343 "$owner_id|$time|I'm having fun with Retwis"

As you can see the user id and time of the post are stored directly inside the string, we don't need to lookup by time or user id in the example application so it is better to compact everything inside the post string.

After we create a post we obtain the post id. We need to LPUSH this post id in every user that's following the author of the post, and of course in the list of posts of the author. This is the file update.php that shows how this is performed:

    include("retwis.php");

    if (!isLoggedIn() || !gt("status")) {
        header("Location:index.php");
        exit;
    }

    $r = redisLink();
    $postid = $r->incr("global:nextPostId");
    $status = str_replace("\n"," ",gt("status"));
    $post = $User['id']."|".time()."|".$status;
    $r->set("post:$postid",$post);
    $followers = $r->smembers("uid:".$User['id'].":followers");
    if ($followers === false) $followers = Array();
    $followers[] = $User['id']; /* Add the post to our own posts too */

    foreach($followers as $fid) {
        $r->push("uid:$fid:posts",$postid,false);
    }
    # Push the post on the timeline, and trim the timeline to the
    # newest 1000 elements.
    $r->push("global:timeline",$postid,false);
    $r->ltrim("global:timeline",0,1000);

    header("Location: index.php");

The core of the function is the `foreach`. We get using SMEMBERS all the followers of the current user, then the loop will LPUSH the post against the uid:`<userid>`:posts of every follower.

Note that we also maintain a timeline with all the posts. In order to do so what is needed is just to LPUSH the post against global:timeline. Let's face it, do you start thinking it was a bit strange to have to sort things added in chronological order using ORDER BY with SQL? I think so indeed.

Paginating updates
---

Now it should be pretty clear how we can user LRANGE in order to get ranges of posts, and render this posts on the screen. The code is simple:

    function showPost($id) {
        $r = redisLink();
        $postdata = $r->get("post:$id");
        if (!$postdata) return false;

        $aux = explode("|",$postdata);
        $id = $aux[0];
        $time = $aux[1];
        $username = $r->get("uid:$id:username");
        $post = join(array_splice($aux,2,count($aux)-2),"|");
        $elapsed = strElapsed($time);
        $userlink = "<a class=\"username\" href=\"profile.php?u=".urlencode($username)."\">".utf8entities($username)."</a>";

        echo('<div class="post">'.$userlink.' '.utf8entities($post)."<br>");
        echo('<i>posted '.$elapsed.' ago via web</i></div>');
        return true;
    }

    function showUserPosts($userid,$start,$count) {
        $r = redisLink();
        $key = ($userid == -1) ? "global:timeline" : "uid:$userid:posts";
        $posts = $r->lrange($key,$start,$start+$count);
        $c = 0;
        foreach($posts as $p) {
            if (showPost($p)) $c++;
            if ($c == $count) break;
        }
        return count($posts) == $count+1;
    }

`showPost` will simply convert and print a Post in HTML while `showUserPosts` get range of posts passing them to `showPosts`.

Following users
---

If user id 1000 (antirez) wants to follow user id 1001 (pippo), we can do this with just two SADD:

SADD uid:1000:following 1001
SADD uid:1001:followers 1000

Note the same pattern again and again, in theory with a relational database the list of following and followers is a single table with fields like `following_id` and `follower_id`. With queries you can extract the followers or following of every user. With a key-value DB that's a bit different as we need to set both the `1000 is following 1001` and `1001 is followed by 1000` relations. This is the price to pay, but on the other side accessing the data is simpler and ultra-fast. And having this things as separated sets allows us to do interesting stuff, for example using SINTER we can have the intersection of 'following' of two different users, so we may add a feature to our Twitter clone so that it is able to say you at warp speed, when you visit somebody' else profile, "you and foobar have 34 followers in common" and things like that.

You can find the code that sets or removes a following/follower relation at follow.php. It is trivial as you can see.

Making it horizontally scalable
---

Gentle reader, if you reached this point you are already an hero, thank you. Before to talk about scaling horizontally it is worth to check the performances on a single server. Retwis is *amazingly fast*, without any kind of cache. On a very slow and loaded server, apache benchmark with 100 parallel clients issuing 100000 requests measured the average pageview to take 5 milliseconds. This means you can serve millions of users every day with just a single Linux box, and this one was monkey asses slow! Go figure with more recent hardware.

So, first of all, probably you will not need more than one server for a lot of applications, even when you have a lot of users. But let's assume we *are* Twitter and need to handle a huge amount of traffic. What to do?

Hashing the key
---

The first thing to do is to hash the key and issue the request on different servers based on the key hash. There are a lot of well known algorithms to do so, for example check the Redis Ruby library client that implements _consistent hashing_, but the general idea is that you can turn your key into a number, and than take the reminder of the division of this number by the number of servers you have:

    server_id = crc32(key) % number_of_servers

This has a lot of problems since if you add one server you need to move too much keys and so on, but this is the general idea even if you use a better hashing scheme like consistent hashing.

Ok, are key accesses distributed among the key space? Well, all the user data will be partitioned among different servers. There are no inter-keys operations used (like SINTER, otherwise you need to care that things you want to intersect will end in the same server. *This is why Redis unlike memcached does not force a specific hashing scheme, it's application specific*). Btw there are keys that are accessed more frequently.

Special keys
---

For example every time we post a new message, we *need* to increment the `global:nextPostId` key. How to fix this problem? A Single server will get a lot if increments. The simplest way to handle this is to have a dedicated server just for increments. This is probably an overkill btw unless you have really a lot of traffic. There is another trick. The ID does not really need to be an incremental number, but just *it needs to be unique*. So you can get a random string long enough to be unlikely (almost impossible, if it's md5-size) to collide, and you are done. We successfully eliminated our main problem to make it really horizontally scalable!

There is another one: global:timeline. There is no fix for this, if you need to take something in order you can split among different servers and *then merge* when you need to get the data back, or take it ordered and use a single key. Again if you really have so much posts per second, you can use a single server just for this. Remember that with commodity hardware Redis is able to handle 100000 writes for second, that's enough even for Twitter, I guess.

Please feel free to use the comments below for questions and feedbacks.
