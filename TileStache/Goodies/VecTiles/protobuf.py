'''
Implementation of Telenav Protobuf encoder.
'''

from map import vector_pb2, common_pb2

from shapely.wkb import loads

__author__ = 'yiqingj'


def _matchRoadType(kind, highway):
    '''
    use highway tag if kind is not available .
    '''
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

def _matchPointType(kind):
    if kind is None:
        return vector_pb2.PT_UNKNOWN
    elif kind == 'traffic_signals':
        return vector_pb2.PT_ROAD
    else:
        return vector_pb2.PT_ROAD


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
        try:
            polyline.latlon.append(int(lat * 1000000))
            polyline.latlon.append(int(lon * 1000000))
        except TypeError:
            print ll
    return

def _handleRoadFeature(feature, tile):
    """
    Handle Road feature, add converted feature to tile instance.
    """
    geom = feature['geometry']
    prop = feature['properties']
    type = geom['type']
    roadType = _matchRoadType(prop['kind'],prop['highway'])
    if roadType == common_pb2.RT_UNKNOWN:
        return
    rf = tile.rf.add()
    rf.roadType = roadType
    rf.roadSubType = vector_pb2.RST_COMMON
    name = prop.get('name')
    if name is not None:
        rf.roadName = unicode(name,'utf-8')
    id = int(feature.get('id'))
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

def _handlePointFeature(feature, tile):
    """
    Handle Point feature, add converted feature to tile instance.
    """
    geom = feature['geometry']
    prop = feature['properties']
    type = geom['type']
    pointType = _matchPointType(prop['kind'])
    if pointType == vector_pb2.PT_UNKNOWN:
        return
    pf = tile.pf.add()
    pf.mainType = vector_pb2.PT_ROAD
    pf.subType = 'a'
    pf.name = prop.get('name') or type
    coord = geom['coordinates']
    pf.spline.latlon.append(int(coord[1]*1000000))
    pf.spline.latlon.append(int(coord[0]*1000000))

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
        type = geom['type']
        if type == 'LineString' or type == 'MultiLineString':
            _handleRoadFeature(feature, tile)
        elif type == 'Point':
            _handlePointFeature(feature, tile)
        else: # at this moment there should be no other types
            print type
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

