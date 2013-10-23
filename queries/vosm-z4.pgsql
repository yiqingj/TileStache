SELECT '' AS highway, name, kind, __geometry__

FROM
(
    --
    -- Urban Areas
    --
    SELECT '' AS name,
           'urban area' AS kind,
           the_geom AS __geometry__
    
    FROM ne_50m_urban_areas
    
    WHERE the_geom && !bbox!

) AS land_usages