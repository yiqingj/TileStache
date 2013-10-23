-- Vector Open Street Map query.
SELECT
    highway,
    name,
    (CASE WHEN highway IN ('motorway', 'motorway_link') THEN 'highway'
          WHEN highway IN ('trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link') THEN 'major_road'
          WHEN highway IN ('residential', 'unclassified', 'road', 'minor') THEN 'minor_road'
          WHEN railway IN ('rail') THEN 'rail'
          ELSE 'unknown' END) AS kind,
    way AS __geometry__,

    --
    -- Negative osm_id is synthetic, with possibly multiple geometry rows.
    --
    (CASE WHEN osm_id < 0 THEN Substr(MD5(ST_AsBinary(way)), 1, 10)
          ELSE osm_id::varchar END) AS __id__

FROM planet_osm_line

WHERE highway IN ('motorway', 'motorway_link')
   OR highway IN ('trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary')
   OR highway IN ('residential', 'unclassified', 'road', 'unclassified')


UNION ALL

SELECT
       highway,
       name,
       COALESCE("aerialway", "aeroway", "natural", "railway", "tourism") AS kind,
       way AS __geometry__,
       osm_id::varchar AS __id__

FROM planet_osm_point

WHERE (
      "aerialway" IN ('station')
   OR "aeroway" IN ('aerodrome', 'airport')
   OR "natural" IN ('peak', 'volcano')
   OR "railway" IN ('halt', 'station', 'tram_stop')
   OR "tourism" IN ('alpine_hut')
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
   AND Area(way) > 1600 -- 4px
