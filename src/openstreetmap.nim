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
## - 1 Not Supported API call: https://wiki.openstreetmap.org/wiki/API_v0.6#Redaction:_POST_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id.2F.23version.2Fredact.3Fredaction.3D.23redaction_id

import asyncdispatch, httpclient, strformat, strutils, xmldomparser, xmldom, uri, httpcore, base64

const
  osm_api_semver* = 0.6                                           ## OpenStreetMap API Version.
  api_url* = "https://api.openstreetmap.org/api/0.6/"             ## OpenStreetMap HTTPS API URL for Production.
  api_dev* = "https://master.apis.dev.openstreetmap.org/api/0.6/" ## OpenStreetMap HTTPS API URL for Development.
  max_str_len = 255  ## API limits length of all key & value strings to a maximum of 255 characters.
  err_msg_len = "OpenStreetMap API limits the length of all key and value strings to a maximum of 255 characters."
  err_msg_ele = "OpenStreetMap API elements must be a string of one of 'node' or 'way' or 'relation'."

type
  OpenStreetMapBase*[HttpType] = object
    timeout*: int8
    username*, password*: string
  OSM* = OpenStreetMapBase[HttpClient]           ## OpenStreetMap  Sync Client.
  AsyncOSM* = OpenStreetMapBase[AsyncHttpClient] ## OpenStreetMap Async Client.


proc osm_http_request(this: OSM | AsyncOSM, endpoint, http_method: string , body = ""): Future[PDocument] {.multisync.} =
  ## Base function for all OpenStreetMap HTTPS API Calls.
  assert http_method in ["GET", "POST", "PUT", "DELETE"], "Invalid HTTP Method."
  assert body.len < max_str_len, err_msg_len
  var client =
    when this is AsyncOSM: newAsyncHttpClient()
    else: newHttpClient(timeout = this.timeout * 1000)
  let basic_auth = base64.encode(this.username.strip & ":" & this.password.strip)
  client.headers["Authorization"] = "Basic " & basic_auth
  client.headers["DNT"] = "1"  # DoNotTrack.
  let responses =
    when this is AsyncOSM: await client.request(url=api_url & endpoint, httpMethod=http_method, body=body)
    else: client.request(url=api_url & endpoint, httpMethod=http_method, body=body)
  result = loadXML(await responses.body)


# API Calls -> Miscellaneous.


proc get_capabilities*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Capabilities:_GET_.2Fapi.2Fcapabilities
  let resp =
    when this is AsyncOSM: await newAsyncHttpClient().get(api_url.replace("/0.6/", "") & "/capabilities")
    else: newHttpClient().get(api_url.replace("/0.6/", "") & "/capabilities")
  result = loadXML(await resp.body)

proc get_bounding_box*(this: OSM | AsyncOSM, left, bottom, right, top: float): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Retrieving_map_data_by_bounding_box:_GET_.2Fapi.2F0.6.2Fmap
  result = await osm_http_request(this, endpoint=fmt"map?bbox={left},{bottom},{right},{top}", http_method="GET")

proc get_permissions*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Retrieving_permissions:_GET_.2Fapi.2F0.6.2Fpermissions
  result = await osm_http_request(this, endpoint="permissions", http_method="GET")


# API Calls -> ChangeSets.


proc put_changeset_create(this: OSM | AsyncOSM, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Create:_PUT_.2Fapi.2F0.6.2Fchangeset.2Fcreate
  result = await osm_http_request(this, endpoint="changeset/create", http_method="PUT", body = $payload)

proc get_changeset*(this: OSM | AsyncOSM, id: int, include_discussion = true): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2Fchangeset.2F.23id.3Finclude_discussion.3Dtrue
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}?include_discussion={include_discussion}", http_method="GET")

proc put_changeset(this: OSM | AsyncOSM, id: int, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Update:_PUT_.2Fapi.2F0.6.2Fchangeset.2F.23id
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}", http_method="PUT", body = $payload)

proc put_changeset_close(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Close:_PUT_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fclose
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/close", http_method="PUT")

proc get_changeset_download*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Download:_GET_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fdownload
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/download", http_method="GET")

proc post_changeset_expand_bbox*(this: OSM | AsyncOSM, id: int, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Expand_Bounding_Box:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fexpand_bbox
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/expand_bbox", http_method="POST", body = $payload)

proc get_changesets_bbox*(this: OSM | AsyncOSM, left, bottom, right, top: float): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  result = await osm_http_request(this, endpoint=fmt"changesets?bbox={left},{bottom},{right},{top}", http_method="GET")

proc get_changesets_user*(this: OSM | AsyncOSM, user: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  result = await osm_http_request(this, endpoint=fmt"changesets?user={user}", http_method="GET")

proc get_changesets_display_name*(this: OSM | AsyncOSM, display_name: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  result = await osm_http_request(this, endpoint=fmt"changesets?display_name={display_name}", http_method="GET")

proc get_changesets_time*(this: OSM | AsyncOSM, time1, time2: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  assert time1 != "", "At least 1 time string must be provided!."
  let t2 = if time2 == "": "" else: "," & time2
  result = await osm_http_request(this, endpoint=fmt"changesets?time={time1}{t2}", http_method="GET")

proc get_changesets_open*(this: OSM | AsyncOSM, open: bool): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  let a = if open: "open=true" else: "closed=true"
  result = await osm_http_request(this, endpoint=fmt"changesets?{a}", http_method="GET")

proc get_changesets_cid*(this: OSM | AsyncOSM, cid: seq[int]): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  let a = cid.join(",")
  result = await osm_http_request(this, endpoint=fmt"changesets?{a}", http_method="GET")

proc post_changeset_upload*(this: OSM | AsyncOSM, id: int, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Diff_upload:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fupload
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/upload", http_method="POST", body = $payload)


# API Calls -> Changeset discussion.


proc post_changeset_comment*(this: OSM | AsyncOSM, id: int, comment: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Comment:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fcomment
  let payload = encodeUrl(comment.strip)
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/comment", http_method="POST", body = $payload)

proc post_changeset_subscribe*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Subscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fsubscribe
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/subscribe", http_method="POST")

proc post_changeset_unsubscribe*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  result = await osm_http_request(this, endpoint=fmt"changeset/{id}/unsubscribe", http_method="POST")


# API Calls -> Elements.


proc put_nodewayrelation_create(this: OSM | AsyncOSM, element: string, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Create:_PUT_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2Fcreate
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/create", http_method="PUT", body = $payload)

proc get_nodewayrelation*(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}", http_method="GET")

proc put_nodewayrelation_update(this: OSM | AsyncOSM, element: string, id: int, payload: PDocument): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Update:_PUT_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}", http_method="PUT", body = $payload)

proc delete_nodewayrelation(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Delete:_DELETE_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}", http_method="DELETE")

proc get_nodewayrelation_history*(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#History:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id.2Fhistory
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}/history", http_method="GET")

proc get_nodewayrelation_version*(this: OSM | AsyncOSM, element: string, id: int, version: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}/{version}", http_method="GET")

proc get_nodewayrelation_parameters*(this: OSM | AsyncOSM, element: string, id: int, parameters: seq[int]): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  let a = parameters.join(",")
  result = await osm_http_request(this, endpoint=fmt"{element}s?{element}s={a}", http_method="GET")

proc get_nodewayrelation_relations*(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}/relations", http_method="GET")

proc get_node_ways*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"node/{id}/ways", http_method="GET")

proc get_wayrelation_full*(this: OSM | AsyncOSM, element: string, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["way", "relation"], err_msg_ele
  result = await osm_http_request(this, endpoint=fmt"{element}/{id}/full", http_method="GET")


# API Calls -> GPS Traces.


proc get_trackpoints*(this: OSM | AsyncOSM, left, bottom, right, top, pageNumber: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"trackpoints?bbox={left},{bottom},{right},{top}&page={pageNumber}", http_method="GET")

# FIXME
# proc post_gpx_create*(this: OSM | AsyncOSM, description, tags, visibility, file: string): Future[PDocument] {.multisync.} =
#   ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
#   assert len(description) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
#   assert len(tags) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
#   assert visibility in ["private", "public", "trackable", "identifiable"], "OpenStreetMap Visibility must be private, public, trackable or identifiable."
# #   It expects the following POST parameters in a multipart/form-data HTTP message:
# #   file	The GPX file containing the track points. Note that for successful processing, the file must contain trackpoints (<trkpt>), not only waypoints, and the trackpoints must have a valid timestamp. Since the file is processed asynchronously, the call will complete successfully even if the file cannot be processed. The file may also be a .tar, .tar.gz or .zip containing multiple gpx files, although it will appear as a single entry in the upload log.
# #   description	The trace description.
# #   tags	A string containing tags for the trace.
# #   public	1 if the trace is public, 0 if not. This exists for backwards compatibility only - the visibility parameter should now be used instead. This value will be ignored if visibility is also provided.
# #   visibility	One of the following: private, public, trackable, identifiable (for explanations see OSM trace upload page or Visibility of GPS traces)
#   let resp =
#     when this is AsyncOSM: await this.client.post(api_url & "gpx/create")
#     else: this.client.post(api_url & "gpx/create")
#   result = loadXML(await resp.body)

proc get_gpx_details*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"gpx/{id}/details", http_method="GET")

proc get_gpx_data*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"gpx/{id}/data", http_method="GET")

proc get_gpx_files*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint="user/gpx_files", http_method="GET")


# API Calls -> Methods for user data.


proc get_user*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"user/{id}", http_method="GET")

proc get_users*(this: OSM | AsyncOSM, users: seq[int]): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let a = users.join(",")
  result = await osm_http_request(this, endpoint=fmt"users?users={a}", http_method="GET")

proc get_user_details*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint="user/details", http_method="GET")

proc get_user_preferences*(this: OSM | AsyncOSM): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint="user/preferences", http_method="GET")

proc put_user_preferences*(this: OSM | AsyncOSM, your_key, value: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"user/preferences/{your_key}", http_method="PUT", body = value)


# API Calls -> Map Notes.


proc get_notes*(this: OSM | AsyncOSM, left, bottom, right, top: int, limit: range[1..10000] = 100, closed: int8 = 7): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"/notes?bbox={left},{bottom},{right},{top}&limit={limit}&closed={closed}", http_method="GET")

proc get_notes*(this: OSM | AsyncOSM, id: int): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"/notes/{id}", http_method="GET")

proc post_notes*(this: OSM | AsyncOSM, lat, lon: float, text: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, err_msg_len
  result = await osm_http_request(this, endpoint=fmt"notes?lat={lat}&lon={lon}&text={encodeUrl(text.strip)}", http_method="POST")

proc post_notes_comment*(this: OSM | AsyncOSM, id: int, text: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, err_msg_len
  result = await osm_http_request(this, endpoint=fmt"notes/{id}/comment?text={encodeUrl(text.strip)}", http_method="POST")

proc post_notes_close*(this: OSM | AsyncOSM, id: int, text: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, err_msg_len
  result = await osm_http_request(this, endpoint=fmt"notes/{id}/comment?text={encodeUrl(text.strip)}", http_method="POST")

proc post_notes_reopen*(this: OSM | AsyncOSM, id: int, text: string): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, err_msg_len
  result = await osm_http_request(this, endpoint=fmt"notes/{id}/comment?text={encodeUrl(text.strip)}", http_method="POST")

proc get_notes_search*(this: OSM | AsyncOSM, q: string, limit: range[1..10000] = 100, closed: int8 = 7): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  result = await osm_http_request(this, endpoint=fmt"notes/search?q={q}&limit={limit}&closed={closed}", http_method="GET")


when is_main_module:
  # Sync client.
  #var osm_client = OSM(timeout: 9, username: "test", password: "test")
  #echo $osm_client.get_capabilities()
  #echo $osm_client.get_bounding_box(90.0, -90.0, 90.0, -90.0)
  #echo $osm_client.get_permissions()
  #echo $osm_client.get_changeset(61972594)
  #echo $osm_client.put_changeset_close(61972594)  # Fails as expected.
  #echo $osm_client.get_changeset_download(61972594)
  # Async client.
  var aosm_client = AsyncOSM(timeout: 9, username: "test", password: "test")
  echo $aosm_client.get_capabilities()
