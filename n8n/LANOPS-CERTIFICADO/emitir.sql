-- n8n · workflow LANOPS-CERTIFICADO · nodo "Postgres: emitir"
-- Execute Query · Execute Once ON · Settings → Always Output Data ON (si no se emite, "Code: HTML" corre igual)
-- Query Parameters: {{ [ JSON.stringify($json) ] }}
-- Inserta el certificado si "Code: firmar" dijo emitir; si ya había uno vigente, no inserta nada.
-- En ambos casos devuelve los datos que pinta la página (0 filas si motivo no es NULL).
WITH p AS (
  SELECT * FROM jsonb_to_record($1::jsonb) AS r(
    motivo text, emitir boolean, usuario int, vacante int, evaluacion int, codigo text,
    codigo_existente text, firma text, fecha_emision timestamp, fecha_caducidad timestamp)),
ins AS (
  INSERT INTO lanops.certificados
    (usuario, vacante, evaluacion, codigo, firma, fecha_emision, fecha_caducidad, estado, veces_verificado)
  SELECT usuario, vacante, evaluacion, codigo, firma, fecha_emision, fecha_caducidad, 'vigente', 0
  FROM p WHERE p.emitir AND p.motivo IS NULL AND p.firma IS NOT NULL
  RETURNING id, usuario, vacante, evaluacion, codigo, fecha_emision, fecha_caducidad, estado),
c AS (
  SELECT * FROM ins
  UNION ALL
  SELECT ce.id, ce.usuario, ce.vacante, ce.evaluacion, ce.codigo, ce.fecha_emision, ce.fecha_caducidad, ce.estado
  FROM lanops.certificados ce JOIN p ON ce.codigo = p.codigo_existente
  WHERE p.motivo IS NULL)
SELECT c.codigo, c.estado,
       to_char(c.fecha_emision, 'YYYY-MM-DD')   AS fecha_emision,
       to_char(c.fecha_caducidad, 'YYYY-MM-DD') AS fecha_caducidad,
       us.nombre AS titular,
       (us.estado_verificacion = 'verificado') AS titular_verificado,
       CASE WHEN us.estado_verificacion = 'verificado' THEN
         (SELECT en.nombre FROM lanops.verificaciones vf JOIN lanops.entidades en ON en.id = vf.entidad
          WHERE vf.usuario = us.id AND vf.estado = 'aprobada' ORDER BY vf.fecha DESC LIMIT 1) END AS entidad,
       v.puesto,
       CASE WHEN v.fuente = 'lanbide' THEN 'Empresa no publicada · oferta gestionada por Lanbide'
            ELSE em.nombre END AS empresa,
       v.ubicacion, v.url_origen AS url_oferta, v.fuente,
       round(x.global::numeric, 2) AS global, x.banda,
       x.d1_match_cv, x.d2_north_star, x.d3_compensacion, x.d4_cultura, x.d5_red_flags,
       x.explicacion, x.hueco,
       to_char(x.fecha, 'YYYY-MM-DD') AS fecha_evaluacion,
       evr.version_rubrica, evr.modelo
FROM c
JOIN lanops.usuarios us     ON us.id = c.usuario
JOIN lanops.vacantes v      ON v.id = c.vacante
JOIN lanops.empresas em     ON em.id = v.empresa
JOIN lanops.evaluaciones x  ON x.id = c.evaluacion
JOIN lanops.evaluadores evr ON evr.id = x.evaluador;
