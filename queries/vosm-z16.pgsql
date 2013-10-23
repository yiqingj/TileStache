-- Vector Open Street Map query.

-- road features
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
--- point features
SELECT highway,
       name,
       COALESCE("aerialway", "aeroway", "amenity", "barrier", "highway", "historic",
                "lock", "man_made", "natural", "power", "railway", "shop", "tourism",
                "waterway") AS kind,
       way AS __geometry__,
       osm_id::varchar AS __id__

FROM planet_osm_point

WHERE (
      "aerialway" IN ('station')
   OR "aeroway" IN ('aerodrome', 'airport', 'helipad')
   OR "amenity" IN ('biergarten', 'bus_station', 'bus_stop', 'car_sharing',
                    'hospital', 'parking', 'picnic_site', 'place_of_worship',
                    'prison', 'pub', 'recycling', 'shelter')
   OR "barrier" IN ('block', 'bollard', 'gate', 'lift_gate')
   OR "highway" IN ('bus_stop', 'ford', 'gate', 'mini_roundabout')
   OR "historic" IN ('archaeological_site')
   OR "lock" IN ('yes')
   OR "man_made" IN ('lighthouse', 'power_wind', 'windmill')
   OR "natural" IN ('cave_entrance', 'peak', 'spring', 'tree', 'volcano')
   OR "power" IN ('generator')
   OR "railway" IN ('halt', 'level_crossing', 'station', 'tram_stop')
   OR "shop" IN ('department_store', 'supermarket')
   OR "tourism" IN ('alpine_hut', 'camp_site', 'caravan_site', 'information', 'viewpoint')
   OR "waterway" IN ('lock')
)

UNION ALL

-- area features

SELECT
       highway,
       name,
       COALESCE("landuse", "leisure", "natural", "highway", "amenity") AS kind,
       way AS __geometry__,
       (CASE WHEN osm_id < 0 THEN Substr(MD5(ST_AsBinary(way)), 1, 10)
             ELSE osm_id::varchar END) AS __id__

FROM planet_osm_polygon

WHERE (
      "landuse" IN ('park', 'forest')
   OR "leisure" IN ('park')
   OR "amenity" IN ('university', 'hospital')
   )
