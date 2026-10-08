-- n8n · workflow LANOPS-FEEDBACK · nodo "Postgres: aprendido"
-- Execute Query · Execute Once ON · Always Output Data ON
-- Query Parameters: {{ [ $('Code: entrada').first().json.usuario, $('Code: entrada').first().json.vacante ] }}
-- Todo lo que pinta la página "Lo que LANOPS ha aprendido de ti", en UNA fila con columnas JSON:
--   aprendidas    exclusiones con descartes detrás (se pueden quitar), con cuántas ofertas abiertas esconden
--                 (sin contar las que el usuario ya descartó)
--   en_camino     sectores con algún descarte por sector que aún no llegan al umbral
--   descartes     ofertas descartadas (se pueden recuperar); oculta = seguiría fuera por una exclusión
--   perfil        el resto de PREFERENCIAS (lo que puso el usuario en su alta): solo consulta; se cambia en el alta
--   tocada_oculta la oferta de esta acción ($2) choca con alguna exclusión
-- Comparaciones = las de prefiltro.sql. Apoyo: empresa/sector solo con su motivo (opción B);
-- palabra/municipio/contrato (reglas de la IA) con cualquier descarte cuya oferta coincida.
WITH n AS (
  SELECT coalesce((SELECT valor::int FROM lanops.configuracion
                   WHERE clave = 'descartes_para_excluir_sector'), 2) AS umbral),
f AS (                       -- rasgos de cada vacante (para comparar con las reglas)
  SELECT v.id, v.puesto, v.fuente, v.estado, v.contrato, e.nombre AS empresa, e.sector,
         lanops.norm(e.nombre) AS emp, lanops.norm(e.sector) AS sec, lanops.norm(v.ubicacion) AS ubic,
         lanops.norm(coalesce(v.puesto, '') || ' ' || coalesce(v.requisitos, '')) AS texto
  FROM lanops.vacantes v JOIN lanops.empresas e ON e.id = v.empresa),
d AS (
  SELECT fb.vacante, fb.motivo, fb.fecha, f.* FROM lanops.feedback fb JOIN f ON f.id = fb.vacante
  WHERE fb.usuario = $1 AND fb.veredicto = 'descartada'),
ex AS (
  SELECT clave, valor, lanops.norm(valor) AS k, fecha_mod FROM lanops.preferencias
  WHERE usuario = $1 AND tipo = 'exclusion'),
apr AS (
  SELECT ex.*,
         (SELECT count(DISTINCT d.vacante) FROM d WHERE
              (ex.clave = 'empresa'   AND d.motivo = 'empresa' AND d.fuente <> 'lanbide' AND d.emp = ex.k)
           OR (ex.clave = 'sector'    AND d.motivo = 'sector'  AND d.sec = ex.k)
           OR (ex.clave = 'palabra'   AND d.texto LIKE '%' || ex.k || '%')
           OR (ex.clave = 'municipio' AND d.ubic  LIKE '%' || ex.k || '%')
           OR (ex.clave = 'contrato'  AND d.contrato = ex.k)) AS descartes,
         (SELECT count(*) FROM f WHERE f.estado = 'abierta' AND f.id NOT IN (SELECT vacante FROM d) AND (
              (ex.clave = 'empresa'   AND f.emp = ex.k)
           OR (ex.clave = 'sector'    AND f.sec LIKE '%' || ex.k || '%')
           OR (ex.clave = 'palabra'   AND f.texto LIKE '%' || ex.k || '%')
           OR (ex.clave = 'municipio' AND f.ubic  LIKE '%' || ex.k || '%')
           OR (ex.clave = 'contrato'  AND f.contrato = ex.k))) AS ocultas
  FROM ex WHERE ex.clave IN ('empresa', 'sector', 'palabra', 'municipio', 'contrato')),
choca AS (                   -- vacantes (de las tocadas o descartadas) que chocan con alguna exclusión
  SELECT f.id FROM f WHERE (f.id = $2 OR f.id IN (SELECT vacante FROM d)) AND EXISTS (SELECT 1 FROM ex WHERE
         (ex.clave = 'empresa'   AND f.emp = ex.k)
      OR (ex.clave = 'palabra'   AND f.texto LIKE '%' || ex.k || '%')
      OR (ex.clave = 'sector'    AND f.sec LIKE '%' || ex.k || '%')
      OR (ex.clave = 'municipio' AND f.ubic LIKE '%' || ex.k || '%')
      OR (ex.clave = 'contrato'  AND f.contrato = ex.k)))
SELECT
  (SELECT umbral FROM n) AS umbral,
  (SELECT coalesce(json_agg(json_build_object('clave', clave, 'valor', valor, 'descartes', descartes, 'ocultas', ocultas,
                                              'desde', to_char(fecha_mod, 'YYYY-MM-DD')) ORDER BY fecha_mod DESC, clave, valor), '[]')
   FROM apr WHERE descartes > 0) AS aprendidas,
  (SELECT coalesce(json_agg(json_build_object('valor', s.valor, 'descartes', s.c,
                                              'faltan', (SELECT umbral FROM n) - s.c) ORDER BY s.valor), '[]')
   FROM (SELECT min(sector) AS valor, sec, count(DISTINCT vacante) AS c FROM d
         WHERE motivo = 'sector' AND sector IS NOT NULL GROUP BY sec) s
   WHERE s.c < (SELECT umbral FROM n)
     AND NOT EXISTS (SELECT 1 FROM ex WHERE ex.clave = 'sector' AND ex.k = s.sec)) AS en_camino,
  (SELECT coalesce(json_agg(json_build_object(
            'vacante', d.vacante, 'puesto', d.puesto,
            'empresa', CASE WHEN d.fuente = 'lanbide' THEN 'Empresa no publicada · oferta gestionada por Lanbide' ELSE d.empresa END,
            'sector', d.sector, 'motivo', d.motivo, 'fecha', to_char(d.fecha, 'YYYY-MM-DD'),
            'oculta', d.vacante IN (SELECT id FROM choca))
          ORDER BY d.fecha DESC, d.vacante DESC), '[]')
   FROM (SELECT * FROM d ORDER BY fecha DESC LIMIT 50) d) AS descartes,
  (SELECT coalesce(json_agg(json_build_object('tipo', pr.tipo, 'clave', pr.clave, 'valor', pr.valor, 'peso', pr.peso)
                            ORDER BY CASE pr.tipo WHEN 'duro' THEN 1 WHEN 'peso' THEN 2 ELSE 3 END, pr.peso DESC NULLS LAST, pr.clave), '[]')
   FROM lanops.preferencias pr
   WHERE pr.usuario = $1
     AND NOT EXISTS (SELECT 1 FROM apr WHERE apr.descartes > 0 AND pr.tipo = 'exclusion'
                     AND apr.clave = pr.clave AND apr.valor = pr.valor)) AS perfil,
  EXISTS (SELECT 1 FROM choca WHERE id = $2) AS tocada_oculta;
