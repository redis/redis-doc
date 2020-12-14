GEOSEARCH is compatible with `GEORADIUS`, in addition to searching for circular areas, it can also support searching for rectangular areas.

The search center point is determined by the following option:

* `FROMMEMBER`: It takes the name of a member already existing inside the geospatial index represented by the sorted set.
* `FROMLOC`: Use parameters to pass longitude and latitude.

The search area is determined by the following options:

* `BYRADIUS`: Similar to GEORADIUS, searching for circular areas according to radius.
* `BYBOX`: Axis-aligned rectangle, determined by height and width.

`WITHCOORD`, `WITHDIST`, `WITHHASH`, `COUNT`, `ASC|DESC` option can refer to `GEORADIUS` commands.

## Search process

1. Calculate the [Minimum bounding box](https://en.wikipedia.org/wiki/Minimum_bounding_box) of the search area. On the one hand, it is used to determine whether the point is in the box(When search box), and the other is to exclude GEOHASH boxes that do not need to be searched (a total of 9).
2. Estimate the geohash encoding bits by radius or max(height/2, width/2) value. Since geohash value represent a box, considering the edge case referenced in [Geohash Wiki](http://en.wikipedia.org/wiki/Geohash), to search fast, we need find the smallest geohash box with surrounding 8 geohash box that could cover all points in radius in the worst case. 
3. According to the minimum bounding box, exclude areas that do not need to be searched, for example, when area.latitude.min < box.min_lat, which means that south, south_west, and south_east will not need to be searched.
4. For each geohash box, we convert it to a score range.
5. For each score range, use `ZRANGEBYSCORE key min max WITHSCORES` to retrieve all point's value and it's score.
6. For each point value and it's score, we can decode the score to a GeoHash area by geohash-int and judge whether the point meets the search conditions. 

@examples

```cli
GEOADD Sicily 13.361389 38.115556 "Palermo" 15.087269 37.502669 "Catania"
GEOADD Sicily 12.758489 38.788135 "edge1"   17.241510 38.788135 "edge2" 
GEORADIUS Sicily 15 37 200 km ASC
GEOSEARCH Sicily FROMLOC 15 37 BYBOX 400 400 km ASC
```