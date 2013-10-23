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

SELECT highway,
       name,
       COALESCE("aerialway", "aeroway", "amenity", "barrier", "highway", "historic",
                "leisure", "lock", "man_made", "natural", "power", "railway", "shop",
                "tourism", "waterway") AS kind,
       way AS __geometry__,
       osm_id::varchar AS __id__

FROM planet_osm_point

WHERE (
      "aerialway" IN ('station')
   OR "aeroway" IN ('aerodrome', 'airport', 'helipad')
   OR "amenity" IN ('atm', 'bank', 'bar', 'bicycle_rental', 'biergarten',
                    'bus_station', 'bus_stop', 'cafe', 'car_sharing', 'cinema',
                    'courthouse', 'drinking_water', 'embassy', 'emergency_phone',
                    'fast_food', 'fire_station', 'fuel', 'hospital', 'library',
                    'parking', 'pharmacy', 'picnic_site', 'place_of_worship',
                    'police', 'post_box', 'post_office', 'prison', 'pub',
                    'recycling', 'restaurant', 'shelter', 'telephone', 'theatre',
                    'toilets', 'veterinary')
   OR "barrier" IN ('block', 'bollard', 'gate', 'lift_gate')
   OR "highway" IN ('bus_stop', 'ford', 'gate', 'mini_roundabout', 'traffic_signals')
   OR "historic" IN ('archaeological_site', 'memorial')
   OR "leisure" IN ('playground', 'slipway')
   OR "man_made" IN ('lighthouse', 'mast', 'power_wind', 'water_tower', 'windmill')
   OR "natural" IN ('cave_entrance', 'peak', 'spring', 'tree', 'volcano')
   OR "power" IN ('generator')
   OR "railway" IN ('halt', 'level_crossing', 'station', 'tram_stop')
   OR "shop" IN ('bakery', 'bicycle', 'books', 'butcher', 'car', 'car_repair',
                 'clothes', 'computer', 'convenience', 'department_store',
                 'doityourself', 'dry_cleaning', 'fashion', 'florist', 'gift',
                 'greengrocer', 'hairdresser', 'jewelry', 'mobile_phone',
                 'optician', 'pet', 'supermarket')
   OR "tourism" IN ('alpine_hut', 'bed_and_breakfast', 'camp_site', 'caravan_site',
                    'chalet', 'guest_house', 'hostel', 'hotel', 'information',
                    'motel', 'museum', 'viewpoint')
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
      "landuse" IN ('park', 'forest', 'residential', 'retail', 'commercial',
                    'industrial', 'railway', 'cemetery', 'grass', 'farmyard',
                    'farm', 'farmland', 'wood', 'meadow', 'village_green',
                    'recreation_ground', 'allotments', 'quarry')
   OR "amenity" IN ('university', 'school', 'college', 'library', 'fuel',
                    'parking', 'cinema', 'theatre', 'place_of_worship', 'hospital')
   )

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
       AND way && !bbox!

) AS water_areas