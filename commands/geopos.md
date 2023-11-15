Return the positions (longitude,latitude) of all the specified members of the geospatial index represented by the sorted set at *key*.

Given a sorted set representing a geospatial index, populated using the `GEOADD` command, it is often useful to obtain back the coordinates of specified members. When the geospatial index is populated via `GEOADD` the coordinates are converted into a 52 bit geohash, so the coordinates returned may not be exactly the ones used in order to add the elements, but small errors may be introduced.

The command can accept a variable number of arguments so it always returns an array of positions even when a single element is specified.

@examples

```cli
GEOADD Sicily 13.361389 38.115556 "Palermo" 15.087269 37.502669 "Catania"
GEOPOS Sicily Palermo Catania NonExisting
```
