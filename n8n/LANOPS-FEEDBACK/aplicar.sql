-- n8n · workflow LANOPS-FEEDBACK · nodo "Postgres: aplicar"
-- Execute Query · Execute Once ON · Always Output Data ON
-- Query Parameters: {{ [ JSON.stringify($('Code: entrada').first().json) ] }}
-- Hace la acción del usuario y devuelve UNA fila con lo que ha pasado y el contexto que necesitan
-- "Code: preparar IA" y "Postgres: aprender" (que corre después y ya ve estos cambios).
--   descartar → INSERT en feedback (veredicto 'descartada', motivo o NULL). Recargar no duplica (nuevo = false).
--   recuperar → DELETE del descarte; devuelve la oferta y el motivo borrado para que "aprender" retire
--               lo aprendido que se quede sin apoyo.
--   olvidar   → DELETE de una regla APRENDIDA (con algún descarte que la respalde; las del alta no se tocan).
--               Si es de empresa o sector, sus descartes quedan sin motivo para que no se reaprenda sola
--               (siguen descartados). Las reglas de la IA no se reaprenden solas: solo con un descarte nuevo.
-- "Aprendida" no es una columna (estructura congelada): se deduce de los descartes, con las mismas
-- comparaciones que prefiltro.sql. Lanbide no publica la empresa (decisión 96): nunca enseña "empresa".
WITH p AS (
  SELECT r.*, lanops.norm(r.valor) AS k FROM jsonb_to_record($1::jsonb) AS r(
    usuario int, accion text, vacante int, motivo text, clave text, valor text)),
vac AS (                     -- la oferta tocada (descartar / recuperar)
  SELECT v.id, v.puesto, v.requisitos, v.ubicacion, v.contrato, v.fuente, e.nombre AS empresa, e.sector
  FROM lanops.vacantes v JOIN lanops.empresas e ON e.id = v.empresa
  JOIN p ON v.id = p.vacante),
ya AS (
  SELECT f.id FROM lanops.feedback f JOIN p ON f.usuario = p.usuario AND f.vacante = p.vacante
  WHERE f.veredicto = 'descartada'),
ins AS (
  INSERT INTO lanops.feedback (usuario, vacante, veredicto, motivo, fecha)
  SELECT p.usuario, vac.id, 'descartada', p.motivo, now()
  FROM p, vac
  WHERE p.accion = 'descartar' AND NOT EXISTS (SELECT 1 FROM ya)
  RETURNING id),
rec AS (
  DELETE FROM lanops.feedback f USING p
  WHERE p.accion = 'recuperar' AND f.usuario = p.usuario AND f.vacante = p.vacante
    AND f.veredicto = 'descartada'
  RETURNING f.id, f.motivo),
d AS (                       -- descartes del usuario con los rasgos que comparan las reglas
  SELECT f.id, f.motivo, v.fuente, lanops.norm(e.nombre) AS emp, lanops.norm(e.sector) AS sec,
         lanops.norm(coalesce(v.puesto, '') || ' ' || coalesce(v.requisitos, '')) AS texto,
         lanops.norm(v.ubicacion) AS ubic, v.contrato
  FROM lanops.feedback f JOIN p ON f.usuario = p.usuario AND p.accion = 'olvidar'
  JOIN lanops.vacantes v ON v.id = f.vacante JOIN lanops.empresas e ON e.id = v.empresa
  WHERE f.veredicto = 'descartada'),
apoyo AS (                   -- descartes que respaldan la regla que se quiere olvidar
  SELECT d.id FROM d, p
  WHERE (p.clave = 'empresa'   AND d.motivo = 'empresa' AND d.fuente <> 'lanbide' AND d.emp = p.k)
     OR (p.clave = 'sector'    AND d.motivo = 'sector'  AND d.sec = p.k)
     OR (p.clave = 'palabra'   AND d.texto LIKE '%' || p.k || '%')
     OR (p.clave = 'municipio' AND d.ubic  LIKE '%' || p.k || '%')
     OR (p.clave = 'contrato'  AND d.contrato = p.k)),
olv AS (
  DELETE FROM lanops.preferencias pr USING p
  WHERE p.accion = 'olvidar' AND EXISTS (SELECT 1 FROM apoyo)
    AND pr.usuario = p.usuario AND pr.tipo = 'exclusion' AND pr.clave = p.clave
    AND lanops.norm(pr.valor) = p.k
  RETURNING pr.clave, pr.valor),
sinmotivo AS (
  UPDATE lanops.feedback f SET motivo = NULL
  FROM p
  WHERE p.clave IN ('empresa', 'sector') AND f.id IN (SELECT id FROM apoyo) AND EXISTS (SELECT 1 FROM olv)
  RETURNING f.id)
SELECT p.accion, p.motivo, p.clave, p.valor,
       vac.id AS vacante, vac.puesto, vac.fuente, vac.ubicacion, vac.contrato,
       left(vac.requisitos, 2500) AS requisitos,
       CASE WHEN vac.fuente = 'lanbide' THEN 'Empresa no publicada · oferta gestionada por Lanbide'
            ELSE vac.empresa END AS empresa,
       CASE WHEN vac.fuente = 'lanbide' THEN NULL ELSE vac.empresa END AS empresa_tocada,
       vac.sector AS sector_tocado,
       (SELECT count(*) FROM ins) > 0 AS nuevo,
       CASE p.accion
         WHEN 'descartar' THEN (SELECT count(*) FROM ins) > 0 OR (SELECT count(*) FROM ya) > 0
         WHEN 'recuperar' THEN (SELECT count(*) FROM rec) > 0
         WHEN 'olvidar'   THEN (SELECT count(*) FROM olv) > 0
         ELSE true END AS hecho,
       (SELECT max(motivo) FROM rec) AS motivo_recuperado,
       (SELECT count(*) FROM sinmotivo) AS descartes_sin_motivo,
       -- contexto para la IA (solo se usa al descartar con motivo)
       (SELECT modelo FROM lanops.evaluadores WHERE tipo = 'ia' AND activo LIMIT 1) AS modelo,
       (SELECT coalesce(json_agg(json_build_object('tipo', pr.tipo, 'clave', pr.clave, 'valor', pr.valor, 'peso', pr.peso)
                                 ORDER BY pr.tipo, pr.clave), '[]')
        FROM lanops.preferencias pr WHERE pr.usuario = p.usuario) AS preferencias
FROM p LEFT JOIN vac ON true;
