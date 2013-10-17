from map import vector_pb2, common_pb2

__author__ = 'yiqingj'


def _highwayToPBRoadType(highway):
    if highway is None:
        return common_pb2.RT_UNKNOWN
    elif highway.startswith('motorway'):
        return common_pb2.RT_HIGHWAY
    elif highway.startswith('primary'):
        return common_pb2.RT_HIGHWAY
    elif highway.startswith('secondary'):
        return common_pb2.RT_ARTERIAL
    elif highway.startswith('trunk'):
        return common_pb2.RT_ARTERIAL
    elif highway == 'residential':
        return common_pb2.RT_LOCAL
    elif highway == 'pedestrian':
        return common_pb2.RT_PEDESTRIAN
    elif highway == 'service':
        return common_pb2.RT_TERMINAL
    elif highway == 'footway':
        return common_pb2.RT_NON_NAVIGABLE
    elif highway.startswith('tertiary'):
        return common_pb2.RT_LOCAL
    elif highway == 'path':
        return common_pb2.RT_NON_NAVIGABLE
    else:
        print 'unknown highway: ', highway
        return common_pb2.RT_UNKNOWN


def _coordToPBPolyline(coordinates, polyline):
    lastLat = 0
    lastLon = 0
    for i in range(len(coordinates)):
        ll = coordinates[i]
        if i == 0:
            lat = lastLat = ll[1]
            lon = lastLon = ll[0]
        else:
            lat = ll[1] - lastLat
            lon = ll[0] - lastLon
            lastLat = ll[1]
            lastLon = ll[0]
        polyline.latlon.append(int(lat * 1000000))
        polyline.latlon.append(int(lon * 1000000))
    return


def _encode(content):
    tile = vector_pb2.VectorMapTile()
    for feature in content['features']:
        geom = feature['geometry']
        prop = feature['properties']
        type = geom['type']
        if type == 'LineString' or 'MultiLineString':
            roadType = _highwayToPBRoadType(prop['highway'])
            if roadType == common_pb2.RT_UNKNOWN:
                continue
            rf = tile.rf.add()
            rf.roadType = roadType
            rf.roadSubType = vector_pb2.RST_COMMON
            name = prop['name']
            if name is not None:
                rf.roadName = name
            id = prop['osm_id']
            if id<0:
                id = -id
            rf.featureID = id
            if type == 'MultiLineString':
                coords = geom['coordinates']
                lastIndex = len(coords)-1
                for i, coord in enumerate(coords):
                    _coordToPBPolyline(coord, rf.lines.add())
                    if i < lastIndex:
                        nrf = tile.rf.add()
                        nrf.CopyFrom(rf)
                        rf = nrf
            else:
                _coordToPBPolyline(geom['coordinates'], rf.lines.add())
        else: # at this moment there should be no other types
            pass
    return tile

def encodeBinary(content):
    return _encode(content).SerializeToString() #protobuf binary data in string form

def encodeText(content):
    return _encode(content).__str__()


