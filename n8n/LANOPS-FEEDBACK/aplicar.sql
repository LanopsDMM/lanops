-- n8n · workflow LANOPS-FEEDBACK · nodo "Postgres: aplicar"
-- Execute Query · Execute Once ON · Always Output Data ON
-- Query Parameters: {{ [ JSON.stringify($('Code: entrada').first().json) ] }}
-- Hace la acción del usuario sobre FEEDBACK (y, en "olvidar", sobre PREFERENCIAS) y devuelve UNA fila
-- que describe qué ha pasado; "Postgres: aprender" corre después y ve ya estos cambios.
--   descartar → INSERT en feedback (veredicto 'descartada', motivo). Recargar no duplica.
--   recuperar → DELETE del descarte. Devuelve la empresa, el sector y el motivo del descarte borrado
--               para que "aprender" retire lo aprendido que se quede sin apoyo.
--   olvidar   → DELETE de la exclusión aprendida + motivo = NULL en los descartes que la enseñaron
--               (siguen descartados, pero ya no cuentan para aprender: no vuelve a aparecer sola).
--               Solo borra exclusiones que tengan algún descarte detrás (= aprendidas); las que puso
--               el usuario en su alta no se tocan desde aquí.
-- "Aprendida" no se guarda en ninguna columna (la estructura está congelada, decisión de Pieza 1):
-- se deduce de los descartes. Lanbide no publica la empresa (decisión 96): sus ofertas nunca enseñan "empresa".
WITH p AS (
  SELECT * FROM jsonb_to_record($1::jsonb) AS r(
    usuario int, accion text, vacante int, motivo text, clave text, valor text)),
vac AS (                     -- la oferta tocada (descartar / recuperar)
  SELECT v.id, v.puesto, v.fuente, e.nombre AS empresa, e.sector
  FROM lanops.vacantes v JOIN lanops.empresas e ON e.id = v.empresa
  JOIN p ON v.id = p.vacante),
ya AS (                      -- ¿ya estaba descartada?
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
apoyo AS (                   -- descartes que enseñaron la exclusión que se quiere olvidar
  SELECT f.id FROM lanops.feedback f
  JOIN p ON f.usuario = p.usuario AND p.accion = 'olvidar'
  JOIN lanops.vacantes v ON v.id = f.vacante
  JOIN lanops.empresas e ON e.id = v.empresa
  WHERE f.veredicto = 'descartada'
    AND ((p.clave = 'empresa' AND f.motivo = 'empresa' AND v.fuente <> 'lanbide'
          AND lanops.norm(e.nombre) = lanops.norm(p.valor))
      OR (p.clave = 'sector' AND f.motivo = 'sector'
          AND lanops.norm(e.sector) = lanops.norm(p.valor)))),
olv AS (
  DELETE FROM lanops.preferencias pr USING p
  WHERE p.accion = 'olvidar' AND EXISTS (SELECT 1 FROM apoyo)
    AND pr.usuario = p.usuario AND pr.tipo = 'exclusion' AND pr.clave = p.clave
    AND lanops.norm(pr.valor) = lanops.norm(p.valor)
  RETURNING pr.clave, pr.valor),
sinmotivo AS (
  UPDATE lanops.feedback f SET motivo = NULL
  WHERE f.id IN (SELECT id FROM apoyo) AND EXISTS (SELECT 1 FROM olv)
  RETURNING f.id)
SELECT p.accion, p.motivo, p.clave, p.valor,
       vac.id AS vacante, vac.puesto, vac.fuente,
       CASE WHEN vac.fuente = 'lanbide' THEN 'Empresa no publicada · oferta gestionada por Lanbide'
            ELSE vac.empresa END AS empresa,
       CASE WHEN vac.fuente = 'lanbide' THEN NULL ELSE vac.empresa END AS empresa_tocada,
       vac.sector AS sector_tocado,
       CASE p.accion
         WHEN 'descartar' THEN (SELECT count(*) FROM ins) > 0 OR (SELECT count(*) FROM ya) > 0
         WHEN 'recuperar' THEN (SELECT count(*) FROM rec) > 0
         WHEN 'olvidar'   THEN (SELECT count(*) FROM olv) > 0
         ELSE true END AS hecho,
       (SELECT max(motivo) FROM rec) AS motivo_recuperado,
       (SELECT count(*) FROM sinmotivo) AS descartes_sin_motivo
FROM p LEFT JOIN vac ON true;
