__author__ = 'yiqingj'

import httplib
from pyramid.config import Configurator
from pyramid.response import Response
from pyramid.httpexceptions import HTTPFound
from pyramid.view import view_config
from wsgiref.simple_server import make_server
import TileStache


@view_config(route_name='home')
def home_view(request):
    return Response('<p>Visit <a href="/howdy?name=lisa">hello</a></p>')

@view_config(route_name='tile')
def getTile(request):

    pass

if __name__ == '__main__':
    config_path = 'tilestache.cfg'
    tsConfig = TileStache.parseConfigfile(config_path)
    config = Configurator()
    config.add_route('home', '/')
    config.add_route('tile', '/')
    config.scan('server')
    app = config.make_wsgi_app()
    server = make_server('0.0.0.0', 6543, app)
    print 'starting server...'
    server.serve_forever()
