__author__ = 'yiqingj'
from TileStache.Vector.proto import common_pb2, vector_pb2


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
        return common_pb2.RT_PEDESTRIAN
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
        polyline.latlon.append(int(lat * 1000000))
        polyline.latlon.append(int(lon * 1000000))
    return


def encode(content):
    tile = vector_pb2.VectorMapTile()
    for feature in content['features']:
        geom = feature['geometry']
        prop = feature['properties']
        type = geom['type']
        if type == 'LineString':
            rf = tile.rf.add()
            rf.roadType = _highwayToPBRoadType(prop['highway'])
            rf.roadSubType = vector_pb2.RST_COMMON
            rf.featureID = prop['osm_id']
            _coordToPBPolyline(geom['coordinates'], rf.lines.add())
        elif type == '': # at this moment there should be no other types
            pass
    return tile.SerializeToString()  #protobuf binary data in string form


