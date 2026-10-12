-- n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Postgres: guardar vacante"
-- Execute Query · Query Parameters: {{ [ JSON.stringify($json.datos) ] }}   (sin cambios)
-- [12-oct] Versión 2.
--   1. Busca la empresa por nombre (sin mayúsculas); si no existe, la crea (anillo 1, tipo_lectura 'manual').
--   2. ¿La misma oferta ya está pegada? = vacante 'usuario' abierta, misma empresa, mismo puesto
--      (sin tildes ni mayúsculas) y mismo enlace sin "?…" ni "#…" ni "https://www.". Si sí, la reutiliza.
--      Sin enlace no se compara así: una web de empleo con una sola página para todas sus ofertas
--      mezclaría ofertas distintas.
--   3. Si no, la inserta. Huella = empresa + texto PEGADO normalizado (no la descripción de Claude,
--      que cambia en cada llamada): pegar exactamente el mismo texto también reutiliza la vacante.
--   4. Devuelve la vacante y, si este usuario ya la tiene evaluada con su CV actual y el evaluador
--      activo, esa evaluación con ya_evaluada = true. El nodo "IF ya evaluada" decide si se llama a Claude.
--   url_origen es varchar(255): si el enlace es más largo, se guarda sin "?…".
WITH d AS (SELECT $1::jsonb AS j),
k AS (
  SELECT j,
         lanops.norm(j->>'puesto') AS puesto_n,
         nullif(lower(regexp_replace(regexp_replace(
           split_part(split_part(coalesce(j->>'url_origen', ''), '#', 1), '?', 1),
           '^https?://(www\.)?', ''), '/+$', '')), '') AS url_n,
         md5('usuario|' || coalesce(lanops.norm(j->>'empresa'), '') || '|' ||
             regexp_replace(coalesce(lanops.norm(coalesce(j->>'texto_pegado', j->>'requisitos')), ''),
                            '\s+', ' ', 'g')) AS hash,
         CASE WHEN length(j->>'url_origen') > 255
              THEN left(split_part(j->>'url_origen', '?', 1), 255)
              ELSE nullif(j->>'url_origen', '') END AS url_guardar
  FROM d
),
emp_existe AS (
  SELECT e.id, e.nombre FROM lanops.empresas e, k WHERE lower(e.nombre) = lower(k.j->>'empresa') ORDER BY e.id LIMIT 1
),
emp_nueva AS (
  INSERT INTO lanops.empresas (nombre, ciudad, anillo, tipo_lectura, activa)
  SELECT k.j->>'empresa', k.j->>'ubicacion', 1, 'manual', true FROM k
  WHERE NOT EXISTS (SELECT 1 FROM emp_existe)
  RETURNING id
),
emp AS (SELECT id FROM emp_existe UNION ALL SELECT id FROM emp_nueva),
previa AS (
  SELECT v.id FROM lanops.vacantes v, k, emp
  WHERE k.url_n IS NOT NULL
    AND v.fuente = 'usuario' AND v.estado = 'abierta' AND v.empresa = emp.id
    AND lanops.norm(v.puesto) = k.puesto_n
    AND lower(regexp_replace(regexp_replace(
          split_part(split_part(coalesce(v.url_origen, ''), '#', 1), '?', 1),
          '^https?://(www\.)?', ''), '/+$', '')) = k.url_n
  ORDER BY v.id LIMIT 1
),
reusa AS (
  UPDATE lanops.vacantes v SET vista_en = now() FROM previa WHERE v.id = previa.id
  RETURNING v.id, v.puesto, v.ubicacion, v.url_origen, v.contrato, v.jornada, v.salario_min, v.requisitos
),
ins AS (
  INSERT INTO lanops.vacantes (empresa, puesto, requisitos, contrato, jornada, ubicacion, salario_min,
                               estado, fuente, url_origen, hash, fecha_pub, vista_en)
  SELECT emp.id, k.j->>'puesto', k.j->>'requisitos', k.j->>'contrato', k.j->>'jornada', k.j->>'ubicacion',
         (k.j->>'salario_min')::int, 'abierta', 'usuario', k.url_guardar, k.hash, now(), now()
  FROM k, emp
  WHERE NOT EXISTS (SELECT 1 FROM previa)
  ON CONFLICT (hash) DO UPDATE SET vista_en = now(), estado = 'abierta'
  RETURNING id, puesto, ubicacion, url_origen, contrato, jornada, salario_min, requisitos
),
vac AS (SELECT * FROM reusa UNION ALL SELECT * FROM ins)
SELECT vac.id AS vacante, vac.puesto, coalesce((SELECT nombre FROM emp_existe), k.j->>'empresa') AS empresa_nombre,
       vac.ubicacion, vac.url_origen, vac.contrato, vac.jornada, vac.salario_min, vac.requisitos,
       ev.id, ev.global, ev.global_personal, ev.banda, ev.d1_match_cv, ev.d2_north_star, ev.d3_compensacion,
       ev.d4_cultura, ev.d5_red_flags, ev.explicacion, ev.hueco,
       (ev.id IS NOT NULL) AS ya_evaluada
FROM vac CROSS JOIN k
LEFT JOIN lanops.evaluaciones ev
       ON ev.vacante = vac.id
      AND ev.usuario = (k.j->>'usuario')::int
      AND ev.evaluador = (k.j->>'evaluador')::int
      AND ev.hash_cv = k.j->>'hash_cv';
