-- LANOPS-FEEDBACK · comprobación read-only tras una prueba (cambiar 201 por el usuario probado).
SELECT 'feedback' AS que, f.vacante::text AS a, coalesce(f.motivo, 'sin motivo') AS b, to_char(f.fecha, 'YYYY-MM-DD HH24:MI') AS c
FROM lanops.feedback f WHERE f.usuario = 201
UNION ALL
SELECT 'exclusion', p.clave, p.valor, to_char(p.fecha_mod, 'YYYY-MM-DD HH24:MI')
FROM lanops.preferencias p WHERE p.usuario = 201 AND p.tipo = 'exclusion'
ORDER BY 1, 2;
