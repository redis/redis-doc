Return the members of a sorted set populated with geospatial information using `GEOADD`, which are within the borders of the area specified with the center location and the maximum distance from the center (the radius).

The common use case for this command is to retrieve geospatial items near a specified point and no far than a given amount of meters (or other units). This allows, for example, to suggest mobile users of an application nearby places.

The radius is specified in one of the following units:

* **m** for meters.
* **km** for kilometers.
* **mi** for miles.
* **ft** for feet.

The command optionally returns additional information using the following options:

* `WITHDIST`: Also return the distance of the returned items from the specified center. The distance is returned in the same unit as the unit specified as the radius argument of the command.
* `WITHCOORD`: Also return the longitude,latitude coordinates of the matching items.
* `WITHHASH`: Also return the raw geohash-encoded sorted set score of the item, in the form of a 52 bit unsigned integer. This is only useful for low level hacks or debugging and is otherwise of little interest for the general user.

The command default is to return unsorted items. Two different sorting methods can be invoked using the following two options:

* `ASC`: Sort returned items from the nearest to the farthest, relative to the center.
* `DESC`: Sort returned items from the farthest to the nearest, relative to the center.

By default all the matching items are returned. It is possible to limit the results to the first N matching items by using the **COUNT `<count>`** option. However note that internally the command needs to perform an effort proportional to the number of items matching the specified area, so to query very large areas with a very small `COUNT` option may be slow even if just a few results are returned. On the other hand `COUNT` can be a very effective way to reduce bandwidth usage if normally just the first results are used.

@return

@array-reply, specifically:

* Without any `WITH` option specified, the command just returns a linear array like ["New York","Milan","Paris"].
* If `WITHCOORD`, `WITHDIST` or `WITHHASH` options are specified, the command returns an array of arrays, where each sub-array represents a single item.

When additional information is returned as an array of arrays for each item, the first item in the sub-array is always the name of the returned item. The other information is returned in the following order as successive elements of the sub-array.

1. The distance from the center as a floating point number, in the same unit specified in the radius.
2. The geohash integer.
3. The coordinates as a two items x,y array (longitude,latitude).

So for example the command `GEORADIUS Sicily 15 37 200 km WITHCOORD WITHDIST` will return each item in the following way:

    ["Palermo","190.4424",["13.361389338970184","38.115556395496299"]]

@examples

```cli
GEOADD Sicily 13.361389 38.115556 "Palermo" 15.087269 37.502669 "Catania"
GEORADIUS Sicily 15 37 200 km WITHDIST
GEORADIUS Sicily 15 37 200 km WITHCOORD
GEORADIUS Sicily 15 37 200 km WITHDIST WITHCOORD
```
