'''
Implementation of Telenav Protobuf encoder.
'''

from map import vector_pb2, common_pb2

from shapely.wkb import loads

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
        return common_pb2.RT_PEDESTRIAN
    elif highway.startswith('tertiary'):
        return common_pb2.RT_LOCAL
    elif highway == 'path':
        return common_pb2.RT_NON_NAVIGABLE
    elif highway == 'unclassified':
        return common_pb2.RT_LOCAL
    else:
        #print 'unknown highway: ', highway
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

def _encode(features):
    try:
        # Assume three-element features
        features = [dict(properties=p, geometry=loads(g).__geo_interface__, id=i) for (g, p, i) in features]

    except ValueError:
        # Fall back to two-element features
        features = [dict(properties=p, geometry=loads(g).__geo_interface__) for (g, p) in features]

    tile = vector_pb2.VectorMapTile()
    for feature in features:
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
            name = prop.get('name')
            if name is not None:
                rf.roadName = unicode(name,'utf-8')
            id = geom.get('id')
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

def encode(out, features):
    pfTile = _encode(features)
    out.write(pfTile.SerializeToString())
def encodeTxt(out, features):
    pfTile = _encode(features)
    out.write(pfTile.__str__())


def merge(out, features):
    pass

def mergeTxt(out, features):
    pass

