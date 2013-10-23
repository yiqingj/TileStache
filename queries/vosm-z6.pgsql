--land feature

SELECT name,  kind, __geometry__

FROM
(
    --
    -- Urban Areas
    --
    SELECT '' AS name,
           'urban area' AS kind,
           the_geom AS __geometry__
    
    FROM ne_10m_urban_areas
    
    WHERE the_geom && !bbox!
    
    --
    -- Parks and Protected Lands
    --
    UNION

    SELECT name,
           'park or protected land' AS kind,
           the_geom AS __geometry__
    
    FROM ne_10m_parks_and_protected_lands
    
    WHERE the_geom && !bbox!

) AS land_usages

UNION ALL

--water feature

SELECT name, kind, __geometry__

FROM
(
    --
    -- Ocean
    --
    SELECT '' AS name,
           'ocean' AS kind,
           the_geom AS __geometry__

    FROM ne_10m_ocean

    WHERE the_geom && !bbox!

    --
    -- Lakes
    --
    UNION

    SELECT name,
           'lake' AS kind,
           the_geom AS __geometry__

    FROM ne_10m_lakes

    WHERE the_geom && !bbox!

    --
    -- Playas
    --
    UNION

    SELECT name,
           'playa' AS kind,
           the_geom AS __geometry__

    FROM ne_10m_playas

    WHERE the_geom && !bbox!

) AS water_areas
