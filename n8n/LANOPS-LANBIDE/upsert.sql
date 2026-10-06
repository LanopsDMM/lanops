WITH filas AS (
  SELECT r.*
  FROM jsonb_to_recordset($1::jsonb) AS r(
    codigo_externo text, puesto text, requisitos text, contrato text, jornada text,
    ubicacion text, salario_min integer, url_origen text, fecha_pub date)
), placeholder AS (
  SELECT id FROM lanops.empresas WHERE nombre = '(Lanbide, sin identificar)'
)
INSERT INTO lanops.vacantes AS v
  (empresa, puesto, requisitos, contrato, jornada, ubicacion, salario_min,
   estado, fuente, url_origen, codigo_externo, hash, fecha_pub, vista_en)
SELECT (SELECT id FROM placeholder), f.puesto, f.requisitos, f.contrato, f.jornada,
       f.ubicacion, f.salario_min, 'abierta', 'lanbide', f.url_origen,
       f.codigo_externo, md5(f.codigo_externo), f.fecha_pub, CURRENT_DATE
FROM filas f
ON CONFLICT (hash) DO UPDATE SET
  puesto      = EXCLUDED.puesto,
  requisitos  = EXCLUDED.requisitos,
  contrato    = EXCLUDED.contrato,
  jornada     = EXCLUDED.jornada,
  ubicacion   = EXCLUDED.ubicacion,
  salario_min = EXCLUDED.salario_min,
  url_origen  = EXCLUDED.url_origen,
  estado      = 'abierta',          -- si reaparece, se reabre
  vista_en    = CURRENT_DATE
WHERE v.fuente = 'lanbide'          -- nunca pisa vacantes de otra fuente
RETURNING (xmax = 0) AS nueva;
