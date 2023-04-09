Return the positions (longitude and latitude) of one _member_ or more that are in the [Redis geospatial index](/docs/data-types/geospatial.md) stored at _key_.

Given a sorted set representing a geospatial index, populated using the `GEOADD` command, it is often useful to obtain back the coordinates of specified members.
When the geospatial index is populated via `GEOADD` the coordinates are converted into a 52-bit Geohash, so the coordinates returned may not be exactly the ones used to add the elements, but small errors may be introduced.

The command can accept a variable number of arguments so it always returns an array of positions even when a single element is specified.

@return

@array-reply, specifically:

The command returns an array where each element is a two-element array representing the longitude and latitude (x,y) of each member name passed as an argument to the command.

Non-existing elements are reported as @nil-reply elements of the array.

@examples

```cli
GEOADD Sicily 13.361389 38.115556 "Palermo" 15.087269 37.502669 "Catania"
GEOPOS Sicily Palermo Catania NonExisting
```
