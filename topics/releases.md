Redis release cycle
===

Redis is system software, and a type of system software that holds user
data, so it is among the most critical pieces of a software stack.

For this reason our release cycle tries hard to make sure that a stable
release is only released when it reaches a sufficiently high level of
stability, even at the cost of a slower release cycle.

A given version of Redis can be at three different levels of stability:

* unstable
* development
* frozen
* release candidate
* stable

Unstable tree
===

The unstable version of Redis is always located in the `unstable` branch in
the [Redis GitHub Repository](http://github.com/antirez/redis).

This is the source tree where most of the new features are developed and
is not considered to be production ready: it may contain critical bugs,
not entirely ready features, and may be unstable.

However, we try hard to make sure that even the unstable branch is
usable most of the time in a development environment without major
issues.

Forked, Frozen, Release candidate tree
===

When a new version of Redis starts to be planned, the unstable branch
(or sometimes the currently stable branch) is forked into a new
branch that has the name of the target release.

For instance, when Redis 2.6 was released as stable, the `unstable` branch
was forked into the `2.8` branch.

This new branch can be at three different levels of stability:
development, frozen, and release candidate.

* Development: new features and bug fixes are committed into the branch, but not everything going into `unstable` is merged here. Only the features that can become stable in a reasonable time frame are merged.
* Frozen: no new feature is added, unless it is almost guaranteed to have zero stability impacts on the source code, and at the same time for some reason it is a very important feature that must be shipped ASAP. Big code changes are only allowed when they are needed in order to fix bugs.
* Release Candidate: only fixes are committed against this release.

Stable tree
===

At some point, when a given Redis release is in the Release Candidate state
for enough time, we observe that the frequency at which critical bugs are
signaled starts to decrease, to the point that for a few weeks we don't have
any serious bugs reported.

When this happens, the release is marked as stable.

Version numbers
---

Stable releases follow the usual `major.minor.patch` versioning schema, with the following special rules:

* The minor is even in stable versions of Redis.
* The minor is odd in unstable, development, frozen, release candidates. For instance the unstable version of 2.8.x will have a version number in the form 2.7.x. In general the unstable version of x.y.z will have a version x.(y-1).z.
* As an unstable version of Redis progresses, the patch level is incremented from time to time, so at a given time you may have 2.7.2, and later 2.7.3 and so forth. However when the release candidate state is reached, the patch level starts from 101. So for instance 2.7.101 is the first release candidate for 2.8, 2.7.105 is Release Candidate 5, and so forth.

Support
---

Older versions are not supported as we try very hard to make the
Redis API mostly backward compatible. Upgrading to newer versions
is usually trivial.

For example, if the current stable release is 2.6.x, we accept bug
reports and provide support for the previous stable release
(2.4.x), but not for older ones such as 2.2.x.

When 2.8 becomes the current stable release, the 2.6.x will be the
oldest supported release.
