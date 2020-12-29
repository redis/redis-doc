Adds the specified geospatial items (latitude, longitude, name) to the specified
key. Data is stored into the key as a sorted set, in a way that makes it possible to later retrieve items using a query by radius with the `GEORADIUS` or `GEORADIUSBYMEMBER` commands, or use `GEOSEARCH` searching within rectangular.

The command takes arguments in the standard format x,y so the longitude must
be specified before the latitude. There are limits to the coordinates that
can be indexed: areas very near to the poles are not indexable. The exact
limits, as specified by EPSG:900913 / EPSG:3785 / OSGEO:41001 are the following:

* Valid longitudes are from -180 to 180 degrees.
* Valid latitudes are from -85.05112878 to 85.05112878 degrees.

The command will report an error when the user attempts to index coordinates outside the specified ranges.

**Note:** there is no **GEODEL** command because you can use `ZREM` in order to remove elements. The Geo index structure is just a sorted set.

## GEOADD options

GEOADD supports a list of options, specified after the name of the key and
before the first longitude argument.
Options are:

* **XX**: Only update elements that already exist. Never add elements.
* **NX**: Don't update already existing elements. Always add new elements.
* **CH**: Modify the return value from the number of new elements added, to the total number of elements changed (CH is an abbreviation of *changed*). Changed elements are **new elements added** and elements already existing for which **the coordinates was updated**. So elements specified in the command line having the same score as they had in the past are not counted. Note: normally the return value of `ZADD` only counts the number of new elements added.

Note: The **XX** and **NX** options are mutually exclusive.

How does it work?
---

The way the sorted set is populated is using a technique called
[Geohash](https://en.wikipedia.org/wiki/Geohash). Latitude and Longitude
bits are interleaved in order to form an unique 52 bit integer. We know
that a sorted set double score can represent a 52 bit integer without losing
precision.

This format allows for radius querying by checking the 1+8 areas needed
to cover the whole radius, and discarding elements outside the radius.
The areas are checked by calculating the range of the box covered removing
enough bits from the less significant part of the sorted set score, and
computing the score range to query in the sorted set for each area.

What Earth model does it use?
---

It just assumes that the Earth is a sphere, since the used distance formula
is the Haversine formula. This formula is only an approximation when applied to the Earth, which is not a perfect sphere. The introduced errors are not an issue when used in the context of social network sites that need to query by radius
and most other applications. However in the worst case the error may be up to
0.5%, so you may want to consider other systems for error-critical applications.

@return

@integer-reply, specifically:

* The number of elements added to the sorted set, not including elements
  already existing for which the score was updated.
  When use `CH` option, will return the number of elements added+updated.

@history

* `>=6.2`: Added the `CH`, `NX` and `XX` options.

@examples

```cli
GEOADD Sicily 13.361389 38.115556 "Palermo" 15.087269 37.502669 "Catania"
GEODIST Sicily Palermo Catania
GEORADIUS Sicily 15 37 100 km
GEORADIUS Sicily 15 37 200 km
```
