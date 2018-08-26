# nim-openstreetmap

- [OpenStreetMap](https://openstreetmap.org) API Lib for [Nim](https://nim-lang.org), Async & Sync, Pull Requests welcome.

![OpenStreetMap](https://raw.githubusercontent.com/juancarlospaco/nim-overpass/master/osm.jpg "OpenStreetMap")


# Install

- `nimble install openstreetmap`


# Use

```nim
import openstreetmap
let osm_client = OSM(timeout: 9, username: "user", password: "pass")
echo $osm_client.get_capabilities() # Check the Docs for more API Calls.
echo $osm_client.get_notes_search(q="Argentina", limit=9)
```


# API

- [Check the OpenStreetMap Wiki](https://wiki.openstreetmap.org/wiki/API_v0.6), the Lib is a 1:1 copy of the official Docs.
- This Library uses API Version `0.6` from Year `2018`.
- Each proc links to the official OSM API docs.
- All procs should return an XML Object `PDocument`.
- The order of the procs follows the order on the OSM Wiki.
- The naming of the procs follows the naming on the OSM Wiki.
- The errors on the procs follows the errors on the OSM Wiki.
- Run the module itself for an Example.


# Support

All OpenStreetMap API is supported, except 2 API calls:

- https://wiki.openstreetmap.org/wiki/API_v0.6#Uploading_traces
- https://wiki.openstreetmap.org/wiki/API_v0.6#Redaction:_POST_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id.2F.23version.2Fredact.3Fredaction.3D.23redaction_id


# FAQ

- How to Edit the OpenStreetMap using this lib ?.

You must provide a valid active OpenStreetMap User and Password.

- This works without SSL ?.

No.

- This works with Asynchronous code ?.

Yes.

- This works with Synchronous code ?.

Yes.

- This requires API Key or Login ?.

[Yes. User and Password.](https://www.openstreetmap.org/user/new)

- This requires Credit Card or Payments ?.

No.

- Why is slow to read data ?.

[Use Overpass for Reading.](https://github.com/juancarlospaco/nim-overpass#nim-overpass) This is optimized for Writing speed.

- How to Search by Name ?.

[Use Nominatim for Search.](https://github.com/juancarlospaco/nim-nominatim#nim-nominatim)

- Can I use the OpenStreetMap data ?.

Yes. [**You MUST give Credit to OpenStreetMap Contributors!.**](https://wiki.openstreetmap.org/wiki/Legal_FAQ#3a._I_would_like_to_use_OpenStreetMap_maps._How_should_I_credit_you.3F)

- Can I use a Sandbox fake server for testing purposes ?.

Yes. Its on the `api_dev` const on the source code.


# Requisites

- None.
