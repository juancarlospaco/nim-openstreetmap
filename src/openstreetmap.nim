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

import asyncdispatch, json, httpclient, strformat, strutils, times, math, xmldomparser, xmldom

const
  osm_api* = 0.6
  api_url* = "https://api.openstreetmap.org/api/0.6/"             ## OpenStreetMap HTTPS API URL for Production.
  api_dev* = "https://master.apis.dev.openstreetmap.org/api/0.6/" ## OpenStreetMap HTTPS API URL for Development.
  max_str_len* = 255  ## API limits length of all key & value strings to a maximum of 255 characters.

let
  http_put*    = newHttpHeaders({"DNT": "1", "X_HTTP_METHOD_OVERRIDE": "PUT"})    ## https://wiki.openstreetmap.org/wiki/API_v0.6#Faking_the_correct_HTTP_methods
  http_delete* = newHttpHeaders({"DNT": "1", "X_HTTP_METHOD_OVERRIDE": "DELETE"}) ## https://wiki.openstreetmap.org/wiki/API_v0.6#Faking_the_correct_HTTP_methods
  http_empty* = newHttpHeaders({"DNT": "1"})  ## "Empty" HTTP Headers.

type
  OpenStreetMapBase*[HttpType] = object
    timeout*: int8
    client: HttpType
  OSM* = OpenStreetMapBase[HttpClient]           ## OpenStreetMap  Sync Client.
  AsyncOSM* = OpenStreetMapBase[AsyncHttpClient] ## OpenStreetMap Async Client.


# API Calls -> Miscellaneous.


proc get_capabilities*(this: OSM | AsyncOSM, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Capabilities:_GET_.2Fapi.2Fcapabilities
  let resp =
    when this is AsyncOSM: await this.client.get(api_url.replace("/0.6/", "") & "/capabilities")
    else: this.client.get(api_url.replace("/0.6/", "") & "/capabilities")
  result = loadXML(await resp.body)

proc get_bounding_box*(this: OSM | AsyncOSM, left, bottom, right, top: float, api_url = api_url): Future[string] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Retrieving_map_data_by_bounding_box:_GET_.2Fapi.2F0.6.2Fmap
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"map?bbox={left},{bottom},{right},{top}")
    else: this.client.get(api_url & fmt"map?bbox={left},{bottom},{right},{top}")
  result = await resp.body

proc get_permissions*(this: OSM | AsyncOSM, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Capabilities:_GET_.2Fapi.2Fcapabilities
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & "permissions")
    else: this.client.get(api_url & "permissions")
  result = loadXML(await resp.body)


# API Calls -> ChangeSets.


proc put_changeset_create(this: OSM | AsyncOSM, payload: PDocument, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Create:_PUT_.2Fapi.2F0.6.2Fchangeset.2Fcreate
  assert len($payload) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  this.client.headers = http_put  # Fake PUT.
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & "changeset/create", body = $payload)
    else: this.client.post(api_url & "changeset/create", body = $payload)
  result = loadXML(await resp.body)

proc get_changeset*(this: OSM | AsyncOSM, id: int, include_discussion = true, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2Fchangeset.2F.23id.3Finclude_discussion.3Dtrue
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"changeset/{id}?include_discussion={include_discussion}")
    else: this.client.get(api_url & fmt"changeset/{id}?include_discussion={include_discussion}")
  result = loadXML(await resp.body)

proc put_changeset(this: OSM | AsyncOSM, id: int, payload: PDocument, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Update:_PUT_.2Fapi.2F0.6.2Fchangeset.2F.23id
  assert len($payload) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  this.client.headers = http_put  # Fake PUT.
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"changeset/{id}", body = $payload)
    else: this.client.post(api_url & fmt"changeset/{id}", body = $payload)
  result = loadXML(await resp.body)

proc put_changeset_close(this: OSM | AsyncOSM, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Close:_PUT_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fclose
  this.client.headers = http_put  # Fake PUT.
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"changeset/{id}/close")
    else: this.client.post(api_url & fmt"changeset/{id}/close")
  result = loadXML(await resp.body)

proc get_changeset_download*(this: OSM | AsyncOSM, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Download:_GET_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fdownload
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"changeset/{id}/download")
    else: this.client.get(api_url & fmt"changeset/{id}/download")
  result = loadXML(await resp.body)

proc post_changeset_expand_bbox*(this: OSM | AsyncOSM, id: int, payload: PDocument, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Expand_Bounding_Box:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fexpand_bbox
  assert len($payload) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"changeset/{id}/expand_bbox", body = $payload)
    else: this.client.post(api_url & fmt"changeset/{id}/expand_bbox", body = $payload)
  result = loadXML(await resp.body)

proc get_changesets_bbox*(this: OSM | AsyncOSM, left, bottom, right, top: float, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"changesets?bbox={left},{bottom},{right},{top}")
    else: this.client.get(api_url & fmt"changesets?bbox={left},{bottom},{right},{top}")
  result = loadXML(await resp.body)

proc get_changesets_user*(this: OSM | AsyncOSM, user: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"changesets?user={user}")
    else: this.client.get(api_url & fmt"changesets?user={user}")
  result = loadXML(await resp.body)

proc get_changesets_display_name*(this: OSM | AsyncOSM, display_name: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"changesets?display_name={display_name}")
    else: this.client.get(api_url & fmt"changesets?display_name={display_name}")
  result = loadXML(await resp.body)

proc get_changesets_time*(this: OSM | AsyncOSM, time1, time2: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  assert time1 != "", "At least 1 time string must be provided!."
  let t2 = if time2 == "": "" else: "," & time2
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"changesets?time={time1}{t2}")
    else: this.client.get(api_url & fmt"changesets?time={time1}{t2}")
  result = loadXML(await resp.body)

proc get_changesets_open*(this: OSM | AsyncOSM, open: bool, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  let a = if open: "open=true" else: "closed=true"
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"changesets?{a}")
    else: this.client.get(api_url & fmt"changesets?{a}")
  result = loadXML(await resp.body)

proc get_changesets_cid*(this: OSM | AsyncOSM, cid: seq[int], api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Query:_GET_.2Fapi.2F0.6.2Fchangesets
  let a = cid.join(",")
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"changesets={a}")
    else: this.client.get(api_url & fmt"changesets={a}")
  result = loadXML(await resp.body)

proc post_changeset_upload*(this: OSM | AsyncOSM, id: int, payload: PDocument, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Diff_upload:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fupload
  assert len($payload) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"changeset/{id}/upload", body = $payload)
    else: this.client.post(api_url & fmt"changeset/{id}/upload", body = $payload)
  result = loadXML(await resp.body)


# API Calls -> Changeset discussion.


proc post_changeset_comment*(this: OSM | AsyncOSM, id: int, comment: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Comment:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fcomment
  let payload = encodeUrl(comment)
  assert len(payload) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"changeset/{id}/comment", body = payload)
    else: this.client.post(api_url & fmt"changeset/{id}/comment", body = payload)
  result = loadXML(await resp.body)

proc post_changeset_subscribe*(this: OSM | AsyncOSM, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Subscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Fsubscribe
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"changeset/{id}/subscribe")
    else: this.client.post(api_url & fmt"changeset/{id}/subscribe")
  result = loadXML(await resp.body)

proc post_changeset_unsubscribe*(this: OSM | AsyncOSM, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"changeset/{id}/unsubscribe")
    else: this.client.post(api_url & fmt"changeset/{id}/unsubscribe")
  result = loadXML(await resp.body)


# API Calls -> Elements.


proc put_nodewayrelation_create(this: OSM | AsyncOSM, element: string, payload: PDocument, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Create:_PUT_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2Fcreate
  assert len($payload) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  assert element in ["node", "way", "relation"], "OpenStreetMap element must be node, way or relation."
  this.client.headers = http_put  # Fake PUT.
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"{element}/create", body = $payload)
    else: this.client.post(api_url & fmt"{element}/create", body = $payload)
  result = loadXML(await resp.body)

proc get_nodewayrelation*(this: OSM | AsyncOSM, element: string, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], "OpenStreetMap element must be node, way or relation."
  let a = cid.join(",")
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"{element}/{id}")
    else: this.client.get(api_url & fmt"{element}/{id}")
  result = loadXML(await resp.body)

proc put_nodewayrelation_update(this: OSM | AsyncOSM, element: string, id: int, payload: PDocument, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Update:_PUT_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert len($payload) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  assert element in ["node", "way", "relation"], "OpenStreetMap element must be node, way or relation."
  this.client.headers = http_put  # Fake PUT.
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"{element}/{id}", body = $payload)
    else: this.client.post(api_url & fmt"{element}/{id}", body = $payload)
  result = loadXML(await resp.body)

proc delete_nodewayrelation(this: OSM | AsyncOSM, element: string, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Delete:_DELETE_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], "OpenStreetMap element must be node, way or relation."
  this.client.headers = http_delete  # Fake DELETE.
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"{element}/{id}")
    else: this.client.post(api_url & fmt"{element}/{id}")
  result = loadXML(await resp.body)

proc get_nodewayrelation_history*(this: OSM | AsyncOSM, element: string, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], "OpenStreetMap element must be node, way or relation."
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"{element}/{id}/history")
    else: this.client.get(api_url & fmt"{element}/{id}/history")
  result = loadXML(await resp.body)

proc get_nodewayrelation_version*(this: OSM | AsyncOSM, element: string, id: int, version: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], "OpenStreetMap element must be node, way or relation."
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"{element}/{id}/{version}")
    else: this.client.get(api_url & fmt"{element}/{id}/{version}")
  result = loadXML(await resp.body)

proc get_nodewayrelation_parameters*(this: OSM | AsyncOSM, element: string, id: int, parameters: seq[int], api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], "OpenStreetMap element must be node, way or relation."
  let a = parameters.join(",")
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"{element}s?{element}s={a}")
    else: this.client.get(api_url & fmt"{element}s?{element}s={a}")
  result = loadXML(await resp.body)

proc get_nodewayrelation_relations*(this: OSM | AsyncOSM, element: string, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["node", "way", "relation"], "OpenStreetMap element must be node, way or relation."
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"{element}/{id}/relations")
    else: this.client.get(api_url & fmt"{element}/{id}/relations")
  result = loadXML(await resp.body)

proc get_node_ways*(this: OSM | AsyncOSM, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"node/{id}/ways")
    else: this.client.get(api_url & fmt"node/{id}/ways")
  result = loadXML(await resp.body)

proc get_wayrelation_full*(this: OSM | AsyncOSM, element: string, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["way", "relation"], "OpenStreetMap element must be node, way or relation."
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"{element}/{id}/full")
    else: this.client.get(api_url & fmt"{element}/{id}/full")
  result = loadXML(await resp.body)

proc get_wayrelation_full*(this: OSM | AsyncOSM, element: string, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert element in ["way", "relation"], "OpenStreetMap element must be node, way or relation."
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"{element}/{id}/full")
    else: this.client.get(api_url & fmt"{element}/{id}/full")
  result = loadXML(await resp.body)


# API Calls -> GPS Traces.


proc get_trackpoints*(this: OSM | AsyncOSM, left, bottom, right, top, pageNumber: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"trackpoints?bbox={left},{bottom},{right},{top}&page={pageNumber}")
    else: this.client.get(api_url & fmt"trackpoints?bbox={left},{bottom},{right},{top}&page={pageNumber}")
  result = loadXML(await resp.body)

# FIXME
proc post_gpx_create*(this: OSM | AsyncOSM, description, tags, visibility, file: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(description) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  assert len(tags) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  assert visibility in ["private", "public", "trackable", "identifiable"], "OpenStreetMap Visibility must be private, public, trackable or identifiable."
#   It expects the following POST parameters in a multipart/form-data HTTP message:
#   file	The GPX file containing the track points. Note that for successful processing, the file must contain trackpoints (<trkpt>), not only waypoints, and the trackpoints must have a valid timestamp. Since the file is processed asynchronously, the call will complete successfully even if the file cannot be processed. The file may also be a .tar, .tar.gz or .zip containing multiple gpx files, although it will appear as a single entry in the upload log.
#   description	The trace description.
#   tags	A string containing tags for the trace.
#   public	1 if the trace is public, 0 if not. This exists for backwards compatibility only - the visibility parameter should now be used instead. This value will be ignored if visibility is also provided.
#   visibility	One of the following: private, public, trackable, identifiable (for explanations see OSM trace upload page or Visibility of GPS traces)
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & "gpx/create")
    else: this.client.post(api_url & "gpx/create")
  result = loadXML(await resp.body)

proc get_gpx_details*(this: OSM | AsyncOSM, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"gpx/{id}/details")
    else: this.client.get(api_url & fmt"gpx/{id}/details")
  result = loadXML(await resp.body)

proc get_gpx_data*(this: OSM | AsyncOSM, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"gpx/{id}/data")
    else: this.client.get(api_url & fmt"gpx/{id}/data")
  result = loadXML(await resp.body)

proc get_gpx_files*(this: OSM | AsyncOSM, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & "user/gpx_files")
    else: this.client.get(api_url & "user/gpx_files")
  result = loadXML(await resp.body)


# API Calls -> Methods for user data.


proc get_user*(this: OSM | AsyncOSM, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & "user/{id}")
    else: this.client.get(api_url & "user/{id}")
  result = loadXML(await resp.body)

proc get_users*(this: OSM | AsyncOSM, users: seq[int], api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let a = parameters.join(",")
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"users?users={a}")
    else: this.client.get(api_url & fmt"users?users={a}")
  result = loadXML(await resp.body)

proc get_user_details*(this: OSM | AsyncOSM, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & "user/details")
    else: this.client.get(api_url & "user/details")
  result = loadXML(await resp.body)

proc get_user_preferences*(this: OSM | AsyncOSM, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & "user/preferences")
    else: this.client.get(api_url & "user/preferences")
  result = loadXML(await resp.body)

proc put_user_preferences*(this: OSM | AsyncOSM, your_key, value: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  assert len(value) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & "user/preferences/{your_key}", body = value)
    else: this.client.get(api_url & "user/preferences/{your_key}", body = value)
  result = loadXML(await resp.body)


# API Calls -> Map Notes.


proc get_notes*(this: OSM | AsyncOSM, left, bottom, right, top: int, limit: range[1..10000] = 100, closed: int8 = 7, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"/notes?bbox={left},{bottom},{right},{top}&limit={limit}&closed={closed}")
    else: this.client.get(api_url & fmt"/notes?bbox={left},{bottom},{right},{top}&limit={limit}&closed={closed}")
  result = loadXML(await resp.body)

proc get_notes*(this: OSM | AsyncOSM, id: int, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"/notes/{id}")
    else: this.client.get(api_url & fmt"/notes/{id}")
  result = loadXML(await resp.body)

proc post_notes*(this: OSM | AsyncOSM, lat, lon: float, text: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  let txt = encodeUrl(text.strip)
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"notes?lat={lat}&lon={lon}&text={txt}")
    else: this.client.post(api_url & fmt"changeset/{id}/unsubscribe")
  result = loadXML(await resp.body)

proc post_notes_comment*(this: OSM | AsyncOSM, id: int, text: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  let txt = encodeUrl(text.strip)
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"notes/{id}/comment?text={txt}")
    else: this.client.post(api_url & fmt"notes/{id}/comment?text={txt}")
  result = loadXML(await resp.body)

proc post_notes_close*(this: OSM | AsyncOSM, id: int, text: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  let txt = encodeUrl(text.strip)
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"notes/{id}/close?text={txt}")
    else: this.client.post(api_url & fmt"notes/{id}/close?text={txt}")
  result = loadXML(await resp.body)

proc post_notes_reopen*(this: OSM | AsyncOSM, id: int, text: string, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Unsubscribe:_POST_.2Fapi.2F0.6.2Fchangeset.2F.23id.2Funsubscribe
  assert len(text) < max_str_len, "API limits length of all key & value strings to a maximum of 255 characters."
  let txt = encodeUrl(text.strip)
  let resp =
    when this is AsyncOSM: await this.client.post(api_url & fmt"notes/{id}/reopen?text={txt}")
    else: this.client.post(api_url & fmt"notes/{id}/reopen?text={txt}")
  result = loadXML(await resp.body)

proc get_notes_search*(this: OSM | AsyncOSM, q: string, limit: range[1..10000] = 100, closed: int8 = 7, api_url = api_url): Future[PDocument] {.multisync.} =
  ## https://wiki.openstreetmap.org/wiki/API_v0.6#Read:_GET_.2Fapi.2F0.6.2F.5Bnode.7Cway.7Crelation.5D.2F.23id
  let resp =
    when this is AsyncOSM: await this.client.get(api_url & fmt"notes/search?q={q}&limit={limit}&closed={closed}")
    else: this.client.get(api_url & fmt"notes/search?q={q}&limit={limit}&closed={closed}")
  result = loadXML(await resp.body)


when is_main_module:
  # Sync client.
  let osm_client = OSM(timeout: 9, client: newHttpClient())
  # echo $osm_client.get_capabilities()
  # echo $osm_client.get_bounding_box(90.0, -90.0, 90.0, -90.0)
  # echo $osm_client.get_permissions()
  # echo $osm_client.get_changeset(61972594)
  # echo $osm_client.put_changeset_close(61972594)  # Fails as expected.
  echo $osm_client.get_changeset_download(61972594)
