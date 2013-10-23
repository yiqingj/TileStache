__author__ = 'yiqingj'

import httplib
from pyramid.config import Configurator
from pyramid.response import Response
from pyramid.httpexceptions import HTTPFound
from pyramid.view import view_config
from wsgiref.simple_server import make_server
import TileStache
from map import vector_pb2

from tests import vectormap


@view_config(route_name='ref')
def refTile(request):
    conn = httplib.HTTPConnection("hqd-vectortilefscdn.telenav.com")
    path = "/maps/v3/VectorTile/TomTom/NA/13M3c/%(zoom)s/%(y)s/%(x)s" % request.matchdict
    conn.request("GET", path)
    response = conn.getresponse()
    data =  response.read()
    pfTile = vector_pb2.VectorMapTile()
    pfTile.ParseFromString(data)
    return Response(
        content_type="text/plain",
        body=pfTile.__str__()
    )

@view_config(route_name='tileFinder')
def getTile(request):
    proj = vectormap.GoogleProjection()
    latlon = map(float,request.matchdict['latlon'].split(','))
    zoom = int(request.matchdict['zoom'])
    tile = proj.fromLLtoTileId(latlon, zoom)
    return Response(
        content_type="text/plain",
        body=tile.__str__()
    )

if __name__ == '__main__':
    config_path = 'tilestache.cfg'
    tsConfig = TileStache.parseConfigfile(config_path)
    config = Configurator()
    config.add_route('ref', '/ref/{zoom}/{y}/{x}')
    config.add_route('tileFinder', '/finder/{zoom}/{latlon}')
    config.scan('server')
    app = config.make_wsgi_app()
    server = make_server('0.0.0.0', 8088, app)
    print 'starting server...'
    server.serve_forever()
