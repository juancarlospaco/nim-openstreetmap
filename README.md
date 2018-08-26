# nim-openstreetmap

- [OpenStreetMap](https://openstreetmap.org) API Lib for [Nim](https://nim-lang.org), Async & Sync, Pull Requests welcome.

![OpenStreetMap](https://raw.githubusercontent.com/juancarlospaco/nim-overpass/master/osm.jpg "OpenStreetMap")


# Install

- `nimble install openstreetmap`


# Use

```nim
import openstreetmap

# Sync client.
let osm_client = OSM(timeout: 9, username: "username", password: "password")
echo $osm_client.get_capabilities()
echo $osm_client.get_bounding_box(90.0, -90.0, 90.0, -90.0)
echo $osm_client.get_permissions()
echo $osm_client.get_changeset(61972594)
echo $osm_client.get_changeset_download(61972594)
echo $osm_client.get_changesets_bbox(90.0, -90.0, 90.0, -90.0)
echo $osm_client.get_changesets_open(true)
echo $osm_client.get_changesets_cid(@[61972594])
echo $osm_client.get_trackpoints(90.0, -90.0, 90.0, -90.0, 1)
echo $osm_client.get_notes(90.0, -90.0, 90.0, -90.0, limit=2)
echo $osm_client.get_notes_search(q="Argentina", limit=2)

# Async client.
proc test {.async.} =
  let
    osm_client = AsyncOSM(timeout: 9, username: "username", password: "password")
    async_resp = await osm_client.get_capabilities()
  echo $async_resp

waitFor(test())
# Check the Docs for more API Calls...
```


# API

- [Check the OpenStreetMap Wiki](https://wiki.openstreetmap.org/wiki/API_v0.6), the Lib is a 1:1 copy of the official Docs.
- This Library uses API Version `0.6` from Year `2018`.
- Each proc links to the official OSM API docs.
- All procs should return an XML Object `PDocument`.
- The order of the procs follows the order on the OSM Wiki.
- The naming of the procs follows the naming on the OSM Wiki.
- The errors on the procs follows the errors on the OSM Wiki.
- API Calls that use HTTP `GET` start with `get_*`.
- API Calls that use HTTP `POST` start with `post_*`.
- API Calls that use HTTP `PUT` start with `put_*`.
- API Calls that use HTTP `DELETE` start with `delete_*`.
- API Calls use [the DoNotTrack HTTP Header.](https://en.wikipedia.org/wiki/Do_Not_Track)
- The `timeout` argument is on Seconds.
- OpenStreetMap API limits the length of all key and value strings to a maximum of 255 characters.
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
