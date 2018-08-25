# nim-openstreetmap

- [OpenStreetMap](https://openstreetmap.org) API Lib for [Nim](https://nim-lang.org), Async & Sync, Pull Requests welcome.

![OpenStreetMap](https://raw.githubusercontent.com/juancarlospaco/nim-overpass/master/osm.jpg)


# Install

- `nimble install openstreetmap`


# Use

```nim
import openstreetmap
echo OSM(timeout: 5).capabilities()  # Check the Docs for more API Calls.
```


# Requisites

- None.


# API

- [Check the OpenStreetMap Wiki](https://wiki.openstreetmap.org/wiki/API_v0.6), since the Lib is a 1:1 copy of the official Docs.
- This Library uses API Version `0.6` from Year `2018`.
- Each proc links to the official OSM API docs.
- All procs should return an XML Object `PDocument`.
- The order of the procs follows the order on the OSM Wiki.
- The naming of the procs follows the naming on the OSM Wiki.
- The errors on the procs follows the errors on the OSM Wiki.
