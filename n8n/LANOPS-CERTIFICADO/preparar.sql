-- n8n · workflow LANOPS-CERTIFICADO · nodo "Postgres: preparar"
-- Execute Query · Execute Once ON
-- Query Parameters: {{ [ $('Code: entrada').first().json.usuario, $('Code: entrada').first().json.vacante ] }}
-- Devuelve SIEMPRE una fila. motivo = NULL si se puede certificar; si no, por qué no:
--   usuario · vacante · vacante_cerrada · sin_evaluacion · banda_baja
-- Reglas: evaluación del evaluador IA activo con el CV actual (hash_cv), vacante abierta,
-- banda Alta o Media (decisión 100; sin exigir verificación, decisiones 25 y 54).
-- La evaluación no se rehace aunque tenga más de reevaluar_si_dias: el certificado muestra su fecha (decisión 102).
-- Si ya hay un certificado vigente de esa misma evaluación, devuelve su código (recargar no duplica).
-- mensaje = texto que se firma: codigo|usuario|vacante|global con 2 decimales|fecha de emisión AAAA-MM-DD.
-- Fechas en hora de Madrid. El mismo formato está en ../LANOPS-VERIFICAR/buscar.sql: si cambia uno, cambia el otro.
WITH p AS (SELECT $1::int AS usuario, $2::int AS vacante),
u AS (SELECT us.id, md5(coalesce(us.cv_texto, '')) AS hash_cv
      FROM lanops.usuarios us JOIN p ON us.id = p.usuario),
ev AS (SELECT id FROM lanops.evaluadores WHERE tipo = 'ia' AND activo),
x AS (SELECT e.id, e.global, e.banda
      FROM lanops.evaluaciones e
      JOIN u ON e.usuario = u.id AND e.hash_cv = u.hash_cv
      JOIN ev ON e.evaluador = ev.id
      JOIN p ON e.vacante = p.vacante
      ORDER BY e.fecha DESC, e.id DESC LIMIT 1),
va AS (SELECT v.estado FROM lanops.vacantes v JOIN p ON v.id = p.vacante),
cfg AS (SELECT coalesce((SELECT valor::int FROM lanops.configuracion
                         WHERE clave = 'caducidad_certificado_dias'), 30) AS dias),
ahora AS (SELECT date_trunc('second', now() AT TIME ZONE 'Europe/Madrid') AS t),
prev AS (SELECT c.codigo FROM lanops.certificados c, x, ahora
         WHERE c.evaluacion = x.id AND c.estado = 'vigente' AND c.fecha_caducidad >= ahora.t
         ORDER BY c.fecha_emision DESC LIMIT 1),
nuevo AS (SELECT gen_random_uuid()::text AS codigo, ahora.t AS fecha_emision FROM ahora)
SELECT p.usuario, p.vacante,
       CASE WHEN NOT EXISTS (SELECT 1 FROM u)              THEN 'usuario'
            WHEN NOT EXISTS (SELECT 1 FROM va)             THEN 'vacante'
            WHEN (SELECT estado FROM va) <> 'abierta'      THEN 'vacante_cerrada'
            WHEN NOT EXISTS (SELECT 1 FROM x)              THEN 'sin_evaluacion'
            WHEN (SELECT banda FROM x) NOT IN ('Alta', 'Media') THEN 'banda_baja'
       END AS motivo,
       (SELECT id FROM x)     AS evaluacion,
       (SELECT global FROM x) AS global,
       (SELECT banda FROM x)  AS banda,
       (SELECT codigo FROM prev) AS codigo_existente,
       nuevo.codigo,
       to_char(nuevo.fecha_emision, 'YYYY-MM-DD"T"HH24:MI:SS') AS fecha_emision,
       to_char(nuevo.fecha_emision + make_interval(days => cfg.dias), 'YYYY-MM-DD"T"HH24:MI:SS') AS fecha_caducidad,
       nuevo.codigo || '|' || p.usuario || '|' || p.vacante || '|'
         || to_char(round((SELECT global FROM x)::numeric, 2), 'FM0.00') || '|'
         || to_char(nuevo.fecha_emision, 'YYYY-MM-DD') AS mensaje
FROM p, cfg, nuevo;
