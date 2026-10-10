-- n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Postgres: guardar vacante"
-- Execute Query · Query Parameters: {{ [ JSON.stringify($json.datos) ] }}
-- Busca la empresa por nombre (sin mayúsculas); si no existe, la crea (anillo 1, tipo_lectura 'manual').
-- Inserta la vacante con fuente 'usuario'. Si ya existía (mismo hash: puesto + empresa + texto), la reutiliza.
WITH d AS (SELECT $1::jsonb AS j),
emp_existe AS (
  SELECT e.id, e.nombre FROM lanops.empresas e, d WHERE lower(e.nombre) = lower(d.j->>'empresa') ORDER BY e.id LIMIT 1
),
emp_nueva AS (
  INSERT INTO lanops.empresas (nombre, ciudad, anillo, tipo_lectura, activa)
  SELECT d.j->>'empresa', d.j->>'ubicacion', 1, 'manual', true FROM d
  WHERE NOT EXISTS (SELECT 1 FROM emp_existe)
  RETURNING id
),
emp AS (SELECT id FROM emp_existe UNION ALL SELECT id FROM emp_nueva),
ins AS (
  INSERT INTO lanops.vacantes (empresa, puesto, requisitos, contrato, jornada, ubicacion, salario_min,
                               estado, fuente, url_origen, hash, fecha_pub, vista_en)
  SELECT emp.id, d.j->>'puesto', d.j->>'requisitos', d.j->>'contrato', d.j->>'jornada', d.j->>'ubicacion',
         (d.j->>'salario_min')::int, 'abierta', 'usuario', d.j->>'url_origen',
         md5('usuario|' || lower(d.j->>'empresa') || '|' || lower(d.j->>'puesto') || '|' || (d.j->>'requisitos')),
         now(), now()
  FROM d, emp
  ON CONFLICT (hash) DO UPDATE SET vista_en = now(), estado = 'abierta'
  RETURNING id, puesto, ubicacion, url_origen, contrato, jornada, salario_min, requisitos
)
SELECT ins.id AS vacante, ins.puesto, coalesce((SELECT nombre FROM emp_existe), d.j->>'empresa') AS empresa_nombre, ins.ubicacion, ins.url_origen,
       ins.contrato, ins.jornada, ins.salario_min, ins.requisitos
FROM ins, d;
