-- n8n · workflow LANOPS-AGENTE · nodo "Postgres: guardar"
-- Execute Query · Execute Once ON · Query Parameters: {{ [ JSON.stringify($json.datos) ] }}
-- 1) Upsert de VACANTES fuente 'agente'. hash = md5('agente|' || empresa || '|' || puesto || '|' || url): estable aunque
--    cambie la descripción. Si ya existía: vista_en = ahora, vuelve a 'abierta' y se actualiza la descripción.
-- 2) EMPRESAS: ultima_lectura = ahora; fallos_seguidos = 0 si se leyó con ofertas, +1 si no.
-- 3) Cierra las vacantes del agente de las empresas leídas bien que llevan más de cierre_agente_dias sin verse.
WITH d AS (SELECT $1::jsonb AS j),
v AS (
  SELECT (x->>'empresa')::int AS empresa, x->>'puesto' AS puesto, x->>'ubicacion' AS ubicacion, x->>'contrato' AS contrato,
         x->>'jornada' AS jornada, (x->>'salario_min')::int AS salario_min, x->>'requisitos' AS requisitos,
         x->>'url_origen' AS url_origen,
         md5('agente|' || (x->>'empresa') || '|' || lower(x->>'puesto') || '|' || coalesce(x->>'url_origen', '')) AS hash
  FROM d, jsonb_array_elements(d.j->'vacantes') x
),
ins AS (
  INSERT INTO lanops.vacantes (empresa, puesto, requisitos, contrato, jornada, ubicacion, salario_min,
                               estado, fuente, url_origen, hash, fecha_pub, vista_en)
  SELECT DISTINCT ON (hash) empresa, puesto, requisitos, contrato, jornada, ubicacion, salario_min,
         'abierta', 'agente', url_origen, hash, now(), now()
  FROM v
  ON CONFLICT (hash) DO UPDATE SET vista_en = now(), estado = 'abierta',
    requisitos = coalesce(EXCLUDED.requisitos, lanops.vacantes.requisitos)
  RETURNING (xmax = 0) AS nueva
),
l AS (
  SELECT (x->>'empresa')::int AS empresa, (x->>'ok')::boolean AS ok FROM d, jsonb_array_elements(d.j->'lecturas') x
),
emp AS (
  UPDATE lanops.empresas e SET ultima_lectura = now(),
         fallos_seguidos = CASE WHEN l.ok THEN 0 ELSE coalesce(e.fallos_seguidos, 0) + 1 END
  FROM l WHERE e.id = l.empresa
  RETURNING e.id, e.nombre, e.fallos_seguidos
),
cerrar AS (
  UPDATE lanops.vacantes x SET estado = 'cerrada'
  WHERE x.fuente = 'agente' AND x.estado = 'abierta'
    AND x.empresa IN (SELECT empresa FROM l WHERE ok)
    AND x.hash NOT IN (SELECT hash FROM v)
    AND x.vista_en < now() - make_interval(days => coalesce((SELECT valor::int FROM lanops.configuracion
                                                              WHERE clave = 'cierre_agente_dias'), 14))
  RETURNING 1
)
SELECT (SELECT count(*) FROM ins WHERE nueva) AS vacantes_nuevas,
       (SELECT count(*) FROM ins WHERE NOT nueva) AS vacantes_vistas_otra_vez,
       (SELECT count(*) FROM cerrar) AS vacantes_cerradas,
       (SELECT coalesce(json_agg(nombre || ' (' || fallos_seguidos || ' fallos seguidos)'), '[]'::json)
          FROM emp WHERE fallos_seguidos >= 2) AS alertas;
