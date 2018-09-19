## Nim-OpenStreetMap
## =================
##
## OpenStreetMap API Lib for Nim, Async & Sync.
##
## - This Library uses API Version 0.6 from Year 2018.
## - Each proc links to the official OSM API docs.
## - All procs should return an XML Object PDocument.
## - The order of the procs follows the order on the OSM Wiki.
## - The naming of the procs follows the naming on the OSM Wiki.
## - The errors on the procs follows the errors on the OSM Wiki.
## - API Calls that use HTTP `GET` start with `get_*`.
## - API Calls that use HTTP `POST` start with `post_*`.
## - API Calls that use HTTP `PUT` start with `put_*`.
## - API Calls that use HTTP `DELETE` start with `delete_*`.
## - API Calls use [the DoNotTrack HTTP Header.](https://en.wikipedia.org/wiki/Do_Not_Track)
## - The `timeout` argument is on Seconds.
## - OpenStreetMap API limits the length of all key and value strings to a maximum of 255 characters.
## - Run the module itself for an Example.
##
## Support
## -------
##
## All OpenStreetMap API is supported, but 2 API calls:
## - https://wiki.openstreetmap.org/wiki/API_v0.6#Uploading_traces
## - https://wiki.openstreetmap.org/wiki/API_v0.6#Redaction:_POST_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id.2F.23version.2Fredact.3Fredaction.3D.23redaction_id

import asyncdispatch, httpclient, strformat, strutils, xmldomparser, xmldom, uri, httpcore, base64

const
  osm_api_version* = 0.6                                          ## OpenStreetMap API Version.
  osm_api_url* = "https://api.openstreetmap.org/api/0.6/"             ## OpenStreetMap HTTPS API URL for Production.
  osm_api_dev* = "https://master.apis.dev.openstreetmap.org/api/0.6/" ## OpenStreetMap HTTPS API URL for Development.
  max_str_len = 255  ## API limits length of all key & value strings to a maximum of 255 characters.
  err_msg_len = "OpenStreetMap API limits the length of all key and value strings to a maximum of 255 characters."
  err_msg_ele = "OpenStreetMap API elements must be a string of one of 'node' or 'way' or 'relation'."

type
  OpenStreetMapBase*[HttpType] = object
    proxy*: Proxy
    timeout*: int8
    use_prod_server*: bool
    username*, password*: string
  OSM* = OpenStreetMapBase[HttpClient]           ## OpenStreetMap  Sync Client.
  AsyncOSM* = OpenStreetMapBase[AsyncHttpClient] ## OpenStreetMap Async Client.

proc osm_http_request(this: OSM | AsyncOSM, endpoint: string, http_method: HttpMethod, body = ""): Future[PDocument] {.multisync.} =
  ## Base function for all OpenStreetMap HTTPS GET/POST/PUT/DELETE API Calls.
  assert endpoint.strip.len > 4, "Invalid OpenStreetMap HTTPS API Endpoint."
  assert body.len < max_str_len, err_msg_len
  var client =
    when this is AsyncOSM: newAsyncHttpClient(
      proxy = when declared(this.proxy): this.proxy else: nil)
    else: newHttpClient(timeout = this.timeout * 1000,
      proxy = when declared(this.proxy): this.proxy else: nil)
  let
    basic_auth = base64.encode(this.username.strip & ":" & this.password.strip)
    osm_apiurl = if this.use_prod_server: osm_api_url else: osm_api_dev
  client.headers["Authorization"] = "Basic " & basic_auth
  client.headers["DNT"] = "1"  # DoNotTrack.
  let responses =
    when this is AsyncOSM: await client.request(url=osm_apiurl & endpoint, httpMethod=http_method, body=body)
    else: client.request(url=osm_apiurl & endpoint, httpMethod=http_method, body=body)
  result = loadXML(await responses.body)


# API Calls -> Miscellaneous.


proc get_capabilities*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Capabilities:_GET_.2Fapi.2Fcapabilities
  let responses =
    when this is AsyncOSM: await newAsyncHttpClient().get(osm_api_url.replace("/0.6/", "/capabilities"))
    else: newHttpClient().get(osm_api_url.replace("/0.6/", "/capabilities"))
  result = loadXML(await responses.body)

proc get_bounding_box*(this: OSM | AsyncOSM, left, bottom, right, top: float): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Retrieving_map_data_by_bounding_box:_GET_.2Fapi.2F0.6.2Fmap
  result = await osm_http_request(this, endpoint=fmt"map?bbox={left},{bottom},{right},{top}", http_method=HttpGet)

proc get_permissions*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Retrieving_permissions:_GET_.2Fapi.2F0.6.2Fpermissions
  result = await osm_http_request(this, endpoint="permissions", http_method=HttpGet)


# API Calls -> ChangeSets.


proc put_changeset_create*(this: OSM | AsyncOSM, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Create:_PUT_.2Fapi.2F0.6.2Fchangeset.2Fcreate
  result = await osm_http_request(this, endpoint="changeset/create", http_method=HttpPut, body = $payload)

proc get_changeset*(this: OSM | AsyncOSM, id: int, include_discussion = true): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2Fchangeset.2F.23id.3Finclude_discussion.3Dtrue
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}?include_discussion={include_discussion}", http_method=HttpGet)

proc put_changeset*(this: OSM | AsyncOSM, id: int, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Update:_PUT_.2Fapi.2F0.6.2Fchangeset.2F.23id
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}", http_method=HttpPut, body = $payload)

proc put_changeset_close*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Close:_PUT_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fclose
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/close", http_method=HttpPut)

proc get_changeset_download*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Download:_GET_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fdownload
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/download", http_method=HttpGet)

proc post_changeset_expand_bbox*(this: OSM | AsyncOSM, id: int, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Expand_Bounding_Box:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fexpand_bbox
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/expand_bbox", http_method=HttpPost, body = $payload)

proc get_changesets_bbox*(this: OSM | AsyncOSM, left, bottom, right, top: float): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  result = await osm_http_request(this, endpoint=fmt"changesets?bbox={left},{bottom},{right},{top}", http_method=HttpGet)

proc get_changesets_user*(this: OSM | AsyncOSM, user: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  result = await osm_http_request(this, endpoint=fmt"changesets?user={user}", http_method=HttpGet)

proc get_changesets_display_name*(this: OSM | AsyncOSM, display_name: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  result = await osm_http_request(this, endpoint=fmt"changesets?display_name={display_name}", http_method=HttpGet)

proc get_changesets_time*(this: OSM | AsyncOSM, time1, time2: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  assert time1 != "", "OpenStreetMap API requires that at least 1 time string must be provided!."
  let t2 = if time2 == "": "" else: "," & time2
  result = await osm_http_request(this, endpoint=fmt"changesets?time={time1}{t2}", http_method=HttpGet)

proc get_changesets_open*(this: OSM | AsyncOSM, open: bool): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  let a = if open: "open=true" else: "closed=true"
  result = await osm_http_request(this, endpoint=fmt"changesets?{a}", http_method=HttpGet)

proc get_changesets_cid*(this: OSM | AsyncOSM, cid: seq[int]): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  let a = cid.join(",")
  result = await osm_http_request(this, endpoint=fmt"changesets?{a}", http_method=HttpGet)

proc post_changeset_upload*(this: OSM | AsyncOSM, id: int, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Diff_upload:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fupload
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/upload", http_method=HttpPost, body = $payload)


# API Calls -> Changeset discussion.


proc post_changeset_comment*(this: OSM | AsyncOSM, id: int, comment: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Comment:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fcomment
  let payload = encodeUrl(comment.strip)
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/comment", http_method=HttpPost, body = $payload)

proc post_changeset_subscribe*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Subscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fsubscribe
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/subscribe", http_method=HttpPost)

proc post_changeset_unsubscribe*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/unsubscribe", http_method=HttpPost)


# API Calls -> Elements.


proc put_nodewayrelation_create*(this: OSM | AsyncOSM, element: string, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Create:_PUT_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2Fcreate
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/create", http_method=HttpPut, body = $payload)

proc get_nodewayrelation*(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}", http_method=HttpGet)

proc put_nodewayrelation_update*(this: OSM | AsyncOSM, element: string, id: int, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Update:_PUT_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}", http_method=HttpPut, body = $payload)

proc delete_nodewayrelation*(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Delete:_DELETE_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}", http_method=HttpDelete)

proc get_nodewayrelation_history*(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#History:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id.2Fhistory
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}/history", http_method=HttpGet)

proc get_nodewayrelation_version*(this: OSM | AsyncOSM, element: string, id: int, version: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}/{version}", http_method=HttpGet)

proc get_nodewayrelation_parameters*(this: OSM | AsyncOSM, element: string, id: int, parameters: seq[int]): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  let a = parameters.join(",")
  result = await osm_http_request(this, endpoint=fmt"{element}s?{element}s={a}", http_method=HttpGet)

proc get_nodewayrelation_relations*(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}/relations", http_method=HttpGet)

proc get_node_ways*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"node/{id}/ways", http_method=HttpGet)

proc get_wayrelation_full*(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}/full", http_method=HttpGet)


# API Calls -> GPS Traces.


proc get_trackpoints*(this: OSM | AsyncOSM, left, bottom, right, top: float, pageNumber: int8): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"trackpoints?bbox={left},{bottom},{right},{top}&page={pageNumber}", http_method=HttpGet)

proc get_gpx_details*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"gpx/{id}/details", http_method=HttpGet)

proc get_gpx_data*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"gpx/{id}/data", http_method=HttpGet)

proc get_gpx_files*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint="user/gpx_files", http_method=HttpGet)


# API Calls -> Methods for user data.


proc get_user*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"user/{id}", http_method=HttpGet)

proc get_users*(this: OSM | AsyncOSM, users: seq[int]): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let a = users.join(",")
  result = await osm_http_request(this, endpoint=fmt"users?users={a}", http_method=HttpGet)

proc get_user_details*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint="user/details", http_method=HttpGet)

proc get_user_preferences*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint="user/preferences", http_method=HttpGet)

proc put_user_preferences*(this: OSM | AsyncOSM, your_key, value: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"user/preferences/{your_key}", http_method=HttpPut, body = value.strip)


# API Calls -> Map Notes.


proc get_notes*(this: OSM | AsyncOSM, left, bottom, right, top: float, limit: range[1..10000] = 100, closed: int8 = 7): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"/notes?bbox={left},{bottom},{right},{top}&limit={limit}&closed={closed}", http_method=HttpGet)

proc get_notes*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"/notes/{id}", http_method=HttpGet)

proc post_notes*(this: OSM | AsyncOSM, lat, lon: float, text: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, err_msg_len
  result = await osm_http_request(this, endpoint=fmt"notes?lat={lat}&lon={lon}&text={encodeUrl(text.strip)}", http_method=HttpPost)

proc post_notes_comment*(this: OSM | AsyncOSM, id: int, text: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, err_msg_len
  result = await osm_http_request(this, endpoint=fmt"notes/{id}/comment?text={encodeUrl(text.strip)}", http_method=HttpPost)

proc post_notes_close*(this: OSM | AsyncOSM, id: int, text: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, err_msg_len
  result = await osm_http_request(this, endpoint=fmt"notes/{id}/comment?text={encodeUrl(text.strip)}", http_method=HttpPost)

proc post_notes_reopen*(this: OSM | AsyncOSM, id: int, text: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, err_msg_len
  result = await osm_http_request(this, endpoint=fmt"notes/{id}/comment?text={encodeUrl(text.strip)}", http_method=HttpPost)

proc get_notes_search*(this: OSM | AsyncOSM, q: string, limit: range[1..10000] = 100, closed: int8 = 7): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"notes/search?q={q}&limit={limit}&closed={closed}", http_method=HttpGet)


when is_main_module:
  # Sync client.
  let osm_client = OSM(timeout: 9, username: "test", password: "test", use_prod_server: true, proxy: nil)
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
      osm_client = AsyncOSM(timeout: 9, username: "test", password: "test", use_prod_server: true, proxy: nil)
      async_resp = await osm_client.get_capabilities()
    echo $async_resp

  waitFor test()
