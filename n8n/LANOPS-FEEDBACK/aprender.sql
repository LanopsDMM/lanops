-- n8n · workflow LANOPS-FEEDBACK · nodo "Postgres: aprender"
-- Execute Query · Execute Once ON · Always Output Data ON
-- Query Parameters:
--   {{ [ JSON.stringify({ ...$('Postgres: aplicar').first().json, usuario: $('Code: entrada').first().json.usuario }) ] }}
-- Opción B (08-oct): lo que LANOPS aprende de los descartes, como exclusiones en PREFERENCIAS.
--   · motivo "empresa" → exclusión de esa empresa al primer descarte (salvo Lanbide: no publica la empresa).
--   · motivo "sector"  → exclusión del sector cuando hay CONFIGURACION.descartes_para_excluir_sector
--                        descartes por sector de ese mismo sector (por defecto 2). Sin sector conocido, no aprende.
--   · tarea, salario, lejos, otro → solo se guardan.
-- Tras "recuperar" un descarte cuyo motivo era empresa o sector, retira la exclusión de esa empresa / sector
-- si se ha quedado sin apoyo (por debajo del umbral). Nunca toca exclusiones que el usuario no aprendió aquí.
-- Devuelve UNA fila: aprendidas [{clave, valor}] y retiradas [{clave, valor}] en esta ejecución.
WITH p AS (
  SELECT * FROM jsonb_to_record($1::jsonb) AS r(
    usuario int, accion text, empresa_tocada text, sector_tocado text, motivo_recuperado text)),
n AS (
  SELECT coalesce((SELECT valor::int FROM lanops.configuracion
                   WHERE clave = 'descartes_para_excluir_sector'), 2) AS umbral),
d AS (                       -- descartes del usuario con motivo que enseña
  SELECT f.vacante, f.motivo, v.fuente, e.nombre AS empresa, e.sector
  FROM lanops.feedback f
  JOIN p ON f.usuario = p.usuario
  JOIN lanops.vacantes v ON v.id = f.vacante
  JOIN lanops.empresas e ON e.id = v.empresa
  WHERE f.veredicto = 'descartada' AND f.motivo IN ('empresa', 'sector')),
apoyo AS (                   -- lo que hoy está respaldado por descartes
  SELECT DISTINCT 'empresa' AS clave, left(empresa, 60) AS valor, lanops.norm(empresa) AS k
  FROM d WHERE motivo = 'empresa' AND fuente <> 'lanbide' AND empresa IS NOT NULL
  UNION ALL
  SELECT 'sector', left(min(sector), 60), lanops.norm(sector)
  FROM d WHERE motivo = 'sector' AND sector IS NOT NULL
  GROUP BY lanops.norm(sector)
  HAVING count(DISTINCT vacante) >= (SELECT umbral FROM n)),
ins AS (
  INSERT INTO lanops.preferencias (usuario, tipo, clave, valor, peso, fecha_mod)
  SELECT p.usuario, 'exclusion', a.clave, a.valor, NULL, now()
  FROM apoyo a, p
  WHERE NOT EXISTS (SELECT 1 FROM lanops.preferencias pr
                    WHERE pr.usuario = p.usuario AND pr.tipo = 'exclusion' AND pr.clave = a.clave
                      AND lanops.norm(pr.valor) = a.k)
  ON CONFLICT DO NOTHING
  RETURNING clave, valor),
del AS (
  DELETE FROM lanops.preferencias pr USING p
  WHERE p.accion = 'recuperar' AND pr.usuario = p.usuario AND pr.tipo = 'exclusion'
    AND ((pr.clave = 'empresa' AND p.motivo_recuperado = 'empresa'
          AND lanops.norm(pr.valor) = lanops.norm(p.empresa_tocada))
      OR (pr.clave = 'sector' AND p.motivo_recuperado = 'sector'
          AND lanops.norm(pr.valor) = lanops.norm(p.sector_tocado)))
    AND NOT EXISTS (SELECT 1 FROM apoyo a WHERE a.clave = pr.clave AND a.k = lanops.norm(pr.valor))
  RETURNING pr.clave, pr.valor)
SELECT (SELECT coalesce(json_agg(json_build_object('clave', clave, 'valor', valor)), '[]') FROM ins) AS aprendidas,
       (SELECT coalesce(json_agg(json_build_object('clave', clave, 'valor', valor)), '[]') FROM del) AS retiradas;
