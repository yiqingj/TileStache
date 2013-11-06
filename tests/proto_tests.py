__author__ = 'yiqingj'

from map import vector_pb2

if __name__ == '__main__':
    f = open('/Users/yiqingj/Documents/workspace/git/mapnik/demo/c++/tile.proto','rb')
    tile = vector_pb2.VectorMapTile()
    tile.ParseFromString(f.read())
    f.close()
    print tile