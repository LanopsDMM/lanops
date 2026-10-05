-- n8n · workflow LANOPS-ENCAJE · nodo "Postgres: prefiltro"
-- Operación: Execute Query · Execute Once ON
-- Query Parameters: {{ [ $json.usuario, $json.solo_gipuzkoa ] }}  (vienen de "Code: entrada")
-- Settings → Always Output Data ON (si no pasa ninguna vacante, el flujo sigue y responde lista vacía)
--   $1 = USUARIOS.id · $2 = true → solo EMPRESAS.anillo = 1 (decisión 31)
-- Devuelve las vacantes que pasan los filtros duros y las exclusiones del usuario,
-- con evaluada = true si ya hay EVALUACION del evaluador IA activo con el mismo hash_cv
-- (caché: esas no se vuelven a mandar a Claude).
-- Regla (decisión 50 y career-ops "silence is absence of signal"):
--   un dato nulo en la vacante NO descarta; solo descarta un dato que contradice.
-- Las vacantes sin evaluar se limitan a CONFIGURACION.max_evaluaciones_por_ejecucion
-- (las más recientes primero) para acotar el gasto de API.
WITH u AS (
  SELECT id, md5(coalesce(cv_texto, '')) AS hash_cv FROM lanops.usuarios WHERE id = $1
), p AS (            -- preferencias del usuario, normalizadas
  SELECT tipo, clave, lanops.norm(valor) AS v FROM lanops.preferencias
  WHERE usuario = $1 AND tipo IN ('duro', 'exclusion')
), ev AS (
  SELECT id FROM lanops.evaluadores WHERE tipo = 'ia' AND activo
), cand AS (
  SELECT v.id AS vacante, v.puesto, v.requisitos, v.ubicacion, e.nombre AS empresa_nombre, v.fecha_pub,
         lanops.norm(v.ubicacion) AS ubic, v.contrato, v.jornada, v.salario_min,
         lanops.norm(e.nombre) AS emp, lanops.norm(e.sector) AS sector, e.tamano,
         lanops.norm(coalesce(v.puesto, '') || ' ' || coalesce(v.requisitos, '')) AS texto
  FROM lanops.vacantes v JOIN lanops.empresas e ON e.id = v.empresa
  WHERE v.estado = 'abierta'
    AND (NOT $2::boolean OR e.anillo = 1)
), filtradas AS (
  SELECT c.* FROM cand c
  WHERE
    -- DUROS: si el usuario puso la clave, la vacante debe coincidir con alguno de sus valores o no constar
        (NOT EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='municipio')
         OR c.ubic IS NULL OR EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='municipio' AND c.ubic LIKE '%' || p.v || '%'))
    AND (NOT EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='contrato')
         OR c.contrato IS NULL OR EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='contrato' AND p.v = c.contrato))
    AND (NOT EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='jornada')
         OR c.jornada IS NULL OR c.jornada = 'indiferente'
         OR EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='jornada' AND p.v = c.jornada))
    AND (NOT EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='salario_min')
         OR c.salario_min IS NULL
         OR c.salario_min >= (SELECT max(nullif(regexp_replace(p.v, '\D', '', 'g'), '')::int)
                              FROM p WHERE tipo='duro' AND clave='salario_min'))
    AND (NOT EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='sector')
         OR c.sector IS NULL OR EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='sector' AND c.sector LIKE '%' || p.v || '%'))
    AND (NOT EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='tamano')
         OR c.tamano IS NULL OR EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='tamano' AND lanops.norm(c.tamano) = p.v))
    AND (NOT EXISTS (SELECT 1 FROM p WHERE tipo='duro' AND clave='ett' AND p.v = 'no')
         OR c.texto !~ '(\mett\M|empresa de trabajo temporal)')
    -- EXCLUSIONES: descartan solo si hay coincidencia
    AND NOT EXISTS (SELECT 1 FROM p WHERE tipo='exclusion' AND (
             (clave='empresa'   AND c.emp = p.v)
          OR (clave='palabra'   AND c.texto LIKE '%' || p.v || '%')
          OR (clave='sector'    AND c.sector LIKE '%' || p.v || '%')
          OR (clave='municipio' AND c.ubic LIKE '%' || p.v || '%')
          OR (clave='contrato'  AND c.contrato = p.v)))
    -- lo que el usuario ya descartó no vuelve
    AND NOT EXISTS (SELECT 1 FROM lanops.feedback f
                    WHERE f.usuario = $1 AND f.vacante = c.vacante AND f.veredicto = 'descartada')
), marcadas AS (
  SELECT f.vacante, f.puesto, f.requisitos, f.ubicacion, f.empresa_nombre,
         f.contrato, f.jornada, f.salario_min, f.fecha_pub,
         EXISTS (SELECT 1 FROM lanops.evaluaciones x, u, ev
                 WHERE x.usuario = u.id AND x.vacante = f.vacante
                   AND x.evaluador = ev.id AND x.hash_cv = u.hash_cv) AS evaluada
  FROM filtradas f
), numeradas AS (
  SELECT m.*, row_number() OVER (PARTITION BY m.evaluada
                                 ORDER BY m.fecha_pub DESC NULLS LAST, m.vacante DESC) AS n
  FROM marcadas m
)
SELECT $1::int AS usuario, (SELECT hash_cv FROM u) AS hash_cv, (SELECT id FROM ev) AS evaluador,
       vacante, puesto, requisitos, ubicacion, empresa_nombre, contrato, jornada, salario_min,
       evaluada
FROM numeradas
WHERE evaluada
   OR n <= coalesce((SELECT valor::int FROM lanops.configuracion
                     WHERE clave = 'max_evaluaciones_por_ejecucion'), 20)
ORDER BY evaluada DESC, fecha_pub DESC NULLS LAST;
