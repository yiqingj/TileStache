SELECT name, kind, __geometry__

FROM
(
    --
    -- Ocean
    --
    SELECT '' AS name,
           'ocean' AS kind,
           the_geom AS __geometry__
    
    FROM ne_110m_ocean
    
    WHERE the_geom && !bbox!
    
    --
    -- Lakes
    --
    UNION

    SELECT name,
           'lake' AS kind,
           the_geom AS __geometry__
    
    FROM ne_110m_lakes
    
    WHERE the_geom && !bbox!

) AS water_areas
