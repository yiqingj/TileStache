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
   OR highway IN ('secondary')


UNION ALL

SELECT
       highway,
       name,
       COALESCE("aeroway") AS kind,
       way AS __geometry__,
       osm_id::varchar AS __id__

FROM planet_osm_point

WHERE (
      "aeroway" IN ('aerodrome', 'airport')
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
      "landuse" IN ('park', 'forest', 'residential', 'retail', 'commercial',
                    'industrial', 'railway', 'cemetery', 'grass', 'farmyard',
                    'farm', 'farmland', 'wood', 'meadow', 'village_green',
                    'recreation_ground', 'allotments', 'quarry')
   OR "leisure" IN ('park', 'garden', 'playground', 'golf_course', 'sports_centre',
                    'pitch', 'stadium', 'common', 'nature_reserve')
   OR "amenity" IN ('university', 'school', 'college', 'library', 'fuel',
                    'parking', 'cinema', 'theatre', 'place_of_worship', 'hospital')
   )
   AND Area(way) > 102400 -- 4px