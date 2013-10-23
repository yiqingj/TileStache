-- Vector Open Street Map query.
SELECT
    highway,
    name,
    (CASE WHEN highway IN ('motorway') THEN 'highway'
          WHEN highway IN ('trunk', 'primary') THEN 'major_road'
          ELSE 'minor_road' END) AS kind,
    way AS __geometry__,

    --
    -- Negative osm_id is synthetic, with possibly multiple geometry rows.
    --
    (CASE WHEN osm_id < 0 THEN Substr(MD5(ST_AsBinary(way)), 1, 10)
          ELSE osm_id::varchar END) AS __id__

FROM planet_osm_line

WHERE highway IN ('motorway')
   OR highway IN ('trunk', 'primary')
   OR highway IN ('secondary', 'tertiary')


UNION ALL

SELECT
       highway,
       name,
       COALESCE("aeroway", "natural") AS kind,
       way AS __geometry__,
       osm_id::varchar AS __id__

FROM planet_osm_point

WHERE (
      "aeroway" IN ('aerodrome', 'airport')
   OR "natural" IN ('peak', 'volcano')
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
   AND Area(way) > 25600 -- 4px


UNION ALL
-- water feature

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
       AND Area(way) > 25600 -- 4px
       AND way && !bbox!

) AS water_areas