CREATE FUNCTION geo_table_as_geojson(tablename text)
RETURNS json
AS
$$
DECLARE

BEGIN

DROP TABLE IF EXISTS dataforgeotableasgeojson;
EXECUTE 'CREATE TEMP TABLE dataforgeotableasgeojson AS SELECT * FROM ' || quote_ident(tablename) || ';';

RETURN row_to_json(featurecollection) as geojson
from 
	(
		select 
		'FeatureCollection' as type, 
		array_to_json(array_agg(features)) as features 
		from 
		(
			select 
			'Feature' as type,
			hstore_to_json
			(
				properties - hstore(akeys(properties), array_fill(null::text, ARRAY[array_length(akeys(properties), 1)]))
			) as properties,
			ST_AsGeoJSON(geometry)::json as geometry
			from
			(
				select 
				hstore(dataforgeotableasgeojson) - '{id, geom}'::text[] as properties, 
				geom as geometry
				from dataforgeotableasgeojson
			) as properties
		) as features
	) as featurecollection;

END;
$$
LANGUAGE plpgsql