---
title: "Redis Geospatial Type"
linkTitle: "Geospatial"
weight: 2
description: >
    Introduction to the Redis Geospatial data type
---

Redis geospatial indexes let you store coordinates and search for them. This data structure is useful for finding nearby points within a given radius or bounding box.

## Examples

Suppose you're building a mobile app that lets you find all of the electric car charging stations closest to your current location.

* Add several locations to the geospatial index:
```
redis:6379> GEOADD locations -122.27652 37.805186 station:1
(integer) 1
redis:6379> GEOADD locations -122.2674626 37.8062344 station:2
(integer) 1
redis:6379> GEOADD locations -122.2469854 37.8104049 station:3
(integer) 1
```

* Find all locations with a 1 kilometer radius of a given location, and return the distance to each location:
```
redis:6379> GEOSEARCH locations FROMLONLAT -122.2612767 37.7936847 BYRADIUS 5 km WITHDIST
1) 1) "station:1"
   2) "1.8523"
2) 1) "station:2"
   2) "1.4979"
3) 1) "station:3"
   2) "2.2441"
```

## Commands

[GEOADD](/commands/geoadd) add a location to a given geospatial index. Note that longitude comes before latitude with this command.
[GEOSEARCH](/commands/geosearch) returns locations with a given radius or rectangular box.

See the [complete list of geospatial index commands](https://redis.io/commands/?group=geo).

## Learn more

* [Redis Geospatial Explained](https://www.youtube.com/watch?v=qftiVQraxmI) introduces geospatial indexes by showing you how to build a map of local park attractions.
