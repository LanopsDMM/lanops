-- n8n · workflow LANOPS-FEEDBACK · nodo "Postgres: aprender"
-- Execute Query · Execute Once ON · Always Output Data ON
-- Entra desde "Code: leer regla" (se preguntó a la IA) o desde la rama false de "IF ¿preguntar a la IA?" (regla = null).
-- Query Parameters:
--   {{ [ JSON.stringify({ ...$('Postgres: aplicar').first().json, usuario: $('Code: entrada').first().json.usuario, regla: $json.regla, porque: $json.porque }) ] }}
-- Lo que LANOPS aprende de los descartes, como exclusiones en PREFERENCIAS (08-oct, opción B + IA):
--   · motivo "empresa" → la empresa, al primer descarte (salvo Lanbide: no publica la empresa).
--   · motivo "sector"  → el sector con CONFIGURACION.descartes_para_excluir_sector descartes por sector (2).
--   · la regla que propuso la IA y validó "Code: leer regla" (palabra, municipio o contrato), si llega.
-- Tras "recuperar", retira lo aprendido que esa oferta respaldaba y se ha quedado sin apoyo.
-- Devuelve UNA fila: aprendidas [{clave, valor, ia}] y retiradas [{clave, valor}] en esta ejecución.
WITH p AS (
  SELECT r.* FROM jsonb_to_record($1::jsonb) AS r(
    usuario int, accion text, vacante int, empresa_tocada text, sector_tocado text, motivo_recuperado text,
    regla jsonb)),
n AS (
  SELECT coalesce((SELECT valor::int FROM lanops.configuracion
                   WHERE clave = 'descartes_para_excluir_sector'), 2) AS umbral),
d AS (                       -- descartes del usuario
  SELECT f.vacante, f.motivo, v.fuente, e.nombre AS empresa, e.sector,
         lanops.norm(e.nombre) AS emp, lanops.norm(e.sector) AS sec,
         lanops.norm(coalesce(v.puesto, '') || ' ' || coalesce(v.requisitos, '')) AS texto,
         lanops.norm(v.ubicacion) AS ubic, v.contrato
  FROM lanops.feedback f
  JOIN p ON f.usuario = p.usuario
  JOIN lanops.vacantes v ON v.id = f.vacante
  JOIN lanops.empresas e ON e.id = v.empresa
  WHERE f.veredicto = 'descartada'),
reglab AS (                  -- reglas fijas (opción B) respaldadas hoy por los descartes
  SELECT DISTINCT 'empresa' AS clave, left(empresa, 60) AS valor, emp AS k
  FROM d WHERE motivo = 'empresa' AND fuente <> 'lanbide' AND empresa IS NOT NULL
  UNION ALL
  SELECT 'sector', left(min(sector), 60), sec
  FROM d WHERE motivo = 'sector' AND sector IS NOT NULL
  GROUP BY sec
  HAVING count(DISTINCT vacante) >= (SELECT umbral FROM n)),
ia AS (                      -- la regla de la IA (ya validada), solo al descartar
  SELECT p.regla->>'clave' AS clave, left(p.regla->>'valor', 60) AS valor, lanops.norm(p.regla->>'valor') AS k
  FROM p WHERE p.accion = 'descartar' AND jsonb_typeof(p.regla) = 'object'
    AND p.regla->>'clave' IN ('palabra', 'municipio', 'contrato') AND coalesce(p.regla->>'valor', '') <> ''),
nuevas AS (
  SELECT clave, valor, k, false AS ia FROM reglab
  UNION ALL
  SELECT clave, valor, k, true FROM ia),
ins AS (
  INSERT INTO lanops.preferencias (usuario, tipo, clave, valor, peso, fecha_mod)
  SELECT DISTINCT ON (x.clave, x.k) p.usuario, 'exclusion', x.clave, x.valor, NULL::int, now()
  FROM nuevas x, p
  WHERE NOT EXISTS (SELECT 1 FROM lanops.preferencias pr
                    WHERE pr.usuario = p.usuario AND pr.tipo = 'exclusion' AND pr.clave = x.clave
                      AND lanops.norm(pr.valor) = x.k)
  ON CONFLICT DO NOTHING
  RETURNING clave, valor),
tocada AS (                  -- rasgos de la oferta recuperada
  SELECT lanops.norm(coalesce(v.puesto, '') || ' ' || coalesce(v.requisitos, '')) AS texto,
         lanops.norm(v.ubicacion) AS ubic, v.contrato
  FROM lanops.vacantes v JOIN p ON v.id = p.vacante AND p.accion = 'recuperar'),
del AS (
  DELETE FROM lanops.preferencias pr USING p
  WHERE p.accion = 'recuperar' AND pr.usuario = p.usuario AND pr.tipo = 'exclusion'
    AND (
      -- reglas fijas: solo si el descarte recuperado era de ese motivo y ya no llega
         (pr.clave = 'empresa' AND p.motivo_recuperado = 'empresa'
          AND lanops.norm(pr.valor) = lanops.norm(p.empresa_tocada)
          AND NOT EXISTS (SELECT 1 FROM reglab b WHERE b.clave = 'empresa' AND b.k = lanops.norm(pr.valor)))
      OR (pr.clave = 'sector' AND p.motivo_recuperado = 'sector'
          AND lanops.norm(pr.valor) = lanops.norm(p.sector_tocado)
          AND NOT EXISTS (SELECT 1 FROM reglab b WHERE b.clave = 'sector' AND b.k = lanops.norm(pr.valor)))
      -- reglas de la IA: si la oferta recuperada la respaldaba y no queda otro descarte que la respalde
      OR (pr.clave IN ('palabra', 'municipio', 'contrato')
          AND EXISTS (SELECT 1 FROM tocada t WHERE
                 (pr.clave = 'palabra'   AND t.texto LIKE '%' || lanops.norm(pr.valor) || '%')
              OR (pr.clave = 'municipio' AND t.ubic  LIKE '%' || lanops.norm(pr.valor) || '%')
              OR (pr.clave = 'contrato'  AND t.contrato = pr.valor))
          AND NOT EXISTS (SELECT 1 FROM d WHERE (
                 (pr.clave = 'palabra'   AND d.texto LIKE '%' || lanops.norm(pr.valor) || '%')
              OR (pr.clave = 'municipio' AND d.ubic  LIKE '%' || lanops.norm(pr.valor) || '%')
              OR (pr.clave = 'contrato'  AND d.contrato = pr.valor)))))
  RETURNING pr.clave, pr.valor)
SELECT (SELECT coalesce(json_agg(json_build_object('clave', i.clave, 'valor', i.valor,
                                                   'ia', EXISTS (SELECT 1 FROM ia WHERE ia.clave = i.clave AND ia.valor = i.valor))), '[]')
        FROM ins i) AS aprendidas,
       (SELECT coalesce(json_agg(json_build_object('clave', clave, 'valor', valor)), '[]') FROM del) AS retiradas;
