-- n8n · workflow LANOPS-ALTA · nodo "Postgres: guardar"
-- Execute Query · credencial Postgres LANOPS · Options → Query Parameters: {{ [ JSON.stringify($json.datos) ] }}
-- $1 = JSON de "Code: preparar". Todo en una sola sentencia (si algo falla, no se guarda nada).
-- Si el email ya existe, ACTUALIZA el perfil (así se edita el perfil volviendo a hacer el alta, decisión 116):
--   reemplaza CV, habilidades y preferencias 'duro'/'peso'; las exclusiones se SUMAN (no se borran las que
--   haya aprendido FEEDBACK); no baja un estado 'pendiente', 'verificado' o 'revocado'.
-- Recomendación [10-oct, LANOPS-INVITAR]: si llega recomendado_por (código ya comprobado en "Code: preparar"), se guarda
--   solo si ese usuario existe, no es la misma persona (otro email) y no ha agotado CONFIGURACION.cupo_recomendaciones.
--   Un recomendado_por ya guardado no se cambia.
-- Verificación: si el dominio del email institucional (o del email) es el de una ENTIDAD activa,
--   VERIFICACIONES 'email_institucional' en 'pendiente' y el usuario en 'pendiente' (no hay correo para confirmar).
WITH d AS (SELECT $1::jsonb AS j),
ent AS (
  SELECT e.id FROM lanops.entidades e, d
  WHERE e.activa AND e.dominio_email IS NOT NULL AND lower(e.dominio_email) = lower(d.j->>'dominio')
  ORDER BY e.id LIMIT 1
),
cupo AS (
  SELECT coalesce((SELECT valor::int FROM lanops.configuracion WHERE clave = 'cupo_recomendaciones'), 3) AS n
),
rec AS (
  SELECT r.id FROM lanops.usuarios r, d, cupo
  WHERE r.id = nullif(d.j->>'recomendado_por', '')::int
    AND lower(r.email) <> lower(d.j->>'email')
    AND (SELECT count(*) FROM lanops.usuarios x WHERE x.recomendado_por = r.id AND lower(x.email) <> lower(d.j->>'email')) < cupo.n
),
u AS (
  INSERT INTO lanops.usuarios (nombre, email, ciudad, titulacion, estado_verificacion, consentimiento_fecha, cv_texto, recomendado_por)
  SELECT j->>'nombre', j->>'email', nullif(j->>'ciudad', ''), nullif(j->>'titulacion', ''),
         CASE WHEN EXISTS (SELECT 1 FROM ent) THEN 'pendiente' ELSE 'sin_verificar' END,
         now(), j->>'cv_texto', (SELECT id FROM rec)
  FROM d
  ON CONFLICT (email) DO UPDATE SET
    recomendado_por = coalesce(lanops.usuarios.recomendado_por, EXCLUDED.recomendado_por),
    nombre = EXCLUDED.nombre, ciudad = EXCLUDED.ciudad, titulacion = EXCLUDED.titulacion,
    consentimiento_fecha = EXCLUDED.consentimiento_fecha, cv_texto = EXCLUDED.cv_texto,
    estado_verificacion = CASE WHEN lanops.usuarios.estado_verificacion IN ('verificado', 'revocado', 'pendiente')
                               THEN lanops.usuarios.estado_verificacion ELSE EXCLUDED.estado_verificacion END
  RETURNING id, (xmax <> 0) AS ya_existia
),
hab AS (
  SELECT DISTINCT ON (lower(x->>'nombre')) x->>'nombre' AS nombre, x->>'categoria' AS categoria, (x->>'nivel')::int AS nivel
  FROM d, jsonb_array_elements(d.j->'habilidades') x
  ORDER BY lower(x->>'nombre'), (x->>'nivel')::int DESC
),
hab_ins AS (
  INSERT INTO lanops.habilidades (nombre, categoria)
  SELECT nombre, categoria FROM hab
  WHERE NOT EXISTS (SELECT 1 FROM lanops.habilidades h WHERE lower(h.nombre) = lower(hab.nombre))
  ON CONFLICT (nombre) DO NOTHING
  RETURNING id, nombre
),
hab_id AS (
  SELECT coalesce(i.id, (SELECT min(h.id) FROM lanops.habilidades h WHERE lower(h.nombre) = lower(hab.nombre))) AS id,
         hab.nivel
  FROM hab LEFT JOIN hab_ins i ON lower(i.nombre) = lower(hab.nombre)
),
uh_borrar AS (
  DELETE FROM lanops.usuario_habilidad uh USING u
  WHERE uh.usuario = u.id AND uh.habilidad NOT IN (SELECT id FROM hab_id WHERE id IS NOT NULL)
),
uh AS (
  INSERT INTO lanops.usuario_habilidad (usuario, habilidad, nivel)
  SELECT DISTINCT ON (hab_id.id) u.id, hab_id.id, hab_id.nivel FROM u, hab_id WHERE hab_id.id IS NOT NULL
  ON CONFLICT (usuario, habilidad) DO UPDATE SET nivel = EXCLUDED.nivel
  RETURNING 1
),
p AS (
  SELECT x->>'tipo' AS tipo, x->>'clave' AS clave, x->>'valor' AS valor, nullif(x->>'peso', '')::int AS peso
  FROM d, jsonb_array_elements(d.j->'preferencias') x
),
pref_borrar AS (
  DELETE FROM lanops.preferencias q USING u
  WHERE q.usuario = u.id AND q.tipo IN ('duro', 'peso')
    AND NOT EXISTS (SELECT 1 FROM p WHERE p.tipo = q.tipo AND p.clave = q.clave AND p.valor = q.valor)
),
pref AS (
  INSERT INTO lanops.preferencias (usuario, tipo, clave, valor, peso, fecha_mod)
  SELECT u.id, p.tipo, p.clave, p.valor, p.peso, now() FROM u, p
  ON CONFLICT (usuario, tipo, clave, valor) DO UPDATE SET peso = EXCLUDED.peso, fecha_mod = EXCLUDED.fecha_mod
  RETURNING 1
),
ver AS (
  INSERT INTO lanops.verificaciones (usuario, entidad, tipo, estado)
  SELECT u.id, ent.id, 'email_institucional', 'pendiente' FROM u, ent
  WHERE NOT EXISTS (SELECT 1 FROM lanops.verificaciones v WHERE v.usuario = u.id AND v.entidad = ent.id)
  RETURNING 1
)
SELECT u.id AS usuario, u.ya_existia,
       (SELECT count(*) FROM uh) AS habilidades,
       (SELECT count(*) FROM pref) AS preferencias,
       (SELECT count(*) FROM ent) > 0 AS entidad_encontrada,
       EXISTS (SELECT 1 FROM rec) AS recomendacion_aceptada,
       (SELECT count(*) FROM lanops.usuarios x WHERE x.recomendado_por = u.id) AS recomendaciones_usadas,
       (SELECT n FROM cupo) AS cupo_recomendaciones
FROM u;
