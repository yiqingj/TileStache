-- Vector Open Street Map query.
SELECT

    highway,
    name,
    (CASE WHEN highway IN ('motorway', 'motorway_link') THEN 'highway'
          WHEN highway IN ('trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link') THEN 'major_road'
          WHEN highway IN ('footpath', 'track', 'footway', 'steps', 'pedestrian', 'path', 'cycleway') THEN 'path'
          WHEN railway IN ('rail', 'tram', 'light_rail', 'narrow_guage', 'monorail') THEN 'rail'
          ELSE 'minor_road' END) AS kind,
    way AS __geometry__,
    --
    -- Negative osm_id is synthetic, with possibly multiple geometry rows.
    --
    (CASE WHEN osm_id < 0 THEN Substr(MD5(ST_AsBinary(way)), 1, 10)
          ELSE osm_id::varchar END) AS __id__

FROM planet_osm_line

WHERE highway IN ('motorway', 'motorway_link')
   OR highway IN ('trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link')
   OR highway IN ('residential', 'unclassified', 'road', 'unclassified', 'service', 'minor')
   OR highway IN ('footpath', 'track', 'footway', 'steps', 'pedestrian', 'path', 'cycleway')
   OR railway IN ('rail', 'tram', 'light_rail', 'narrow_guage', 'monorail')


UNION ALL

SELECT
       highway,
       name,
       COALESCE("aerialway", "aeroway", "amenity", "barrier", "highway",
                "lock", "man_made", "natural", "power", "railway", "tourism",
                "waterway") AS kind,
       way AS __geometry__,
       osm_id::varchar AS __id__

FROM planet_osm_point

WHERE (
      "aerialway" IN ('station')
   OR "aeroway" IN ('aerodrome', 'airport')
   OR "amenity" IN ('hospital', 'parking')
   OR "barrier" IN ('gate')
   OR "highway" IN ('gate', 'mini_roundabout')
   OR "man_made" IN ('lighthouse', 'power_wind')
   OR "natural" IN ('cave_entrance', 'peak', 'spring', 'volcano')
   OR "power" IN ('generator')
   OR "railway" IN ('halt', 'level_crossing', 'station', 'tram_stop')
   OR "tourism" IN ('alpine_hut')
   OR "waterway" IN ('lock')
)

UNION ALL

-- area features

SELECT
       highway,
       name,
       COALESCE("landuse", "leisure", "natural", "highway", "amenity") AS kind,
       way AS __geometry__,

       --
       -- Negative osm_id is synthetic, with possibly multiple geometry rows.
       --
       (CASE WHEN osm_id < 0 THEN Substr(MD5(ST_AsBinary(way)), 1, 10)
             ELSE osm_id::varchar END) AS __id__

FROM planet_osm_polygon

WHERE (
      "landuse" IN ('park', 'forest')
   OR "leisure" IN ('park')
   OR "amenity" IN ('university', 'hospital')
   )
   AND Area(way) > 100 -- 4px

UNION ALL

SELECT '' AS highway, name, kind, __geometry__, __id__

FROM
(
    --
    -- Ocean
    --
    SELECT '' AS name,
           'ocean' AS kind,
           the_geom AS __geometry__,
           gid::varchar AS __id__

    FROM water_polygons

    WHERE the_geom && !bbox!

    --
    -- Other water areas
    --
    UNION

    SELECT name,
           COALESCE("waterway", "natural", "landuse") AS kind,
           way AS __geometry__,

           --
           -- Negative osm_id is synthetic, with possibly multiple geometry rows.
           --
           (CASE WHEN osm_id < 0 THEN Substr(MD5(ST_AsBinary(way)), 1, 10)
                 ELSE osm_id::varchar END) AS __id__

    FROM planet_osm_polygon

    WHERE (
         "waterway" IN ('riverbank')
       OR "natural" IN ('water')
       OR "landuse" IN ('basin', 'reservoir')
       )
       AND Area(way) > 100 -- 4px
       AND way && !bbox!

) AS water_areas