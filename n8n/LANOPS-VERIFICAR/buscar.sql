-- n8n · workflow LANOPS-VERIFICAR · nodo "Postgres: buscar"
-- Execute Query · Execute Once ON · Settings → Always Output Data ON (código inexistente → item vacío)
-- Query Parameters: {{ [ String($('Webhook /verificar').first().json.query.c || '') ] }}
-- Datos del certificado + "mensaje" recalculado con el MISMO formato que ../LANOPS-CERTIFICADO/preparar.sql:
--   codigo|usuario|vacante|global con 2 decimales|fecha de emisión AAAA-MM-DD
-- caducado_ahora: true si la fecha de caducidad ya pasó (hora de Madrid).
SELECT c.codigo, c.firma, c.estado, c.veces_verificado,
       c.codigo || '|' || c.usuario || '|' || c.vacante || '|'
         || to_char(round(x.global::numeric, 2), 'FM0.00') || '|'
         || to_char(c.fecha_emision, 'YYYY-MM-DD') AS mensaje,
       (c.fecha_caducidad < now() AT TIME ZONE 'Europe/Madrid') AS caducado_ahora,
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
       v.ubicacion, v.url_origen AS url_oferta,
       round(x.global::numeric, 2) AS global, x.banda,
       x.d1_match_cv, x.d2_north_star, x.d3_compensacion, x.d4_cultura, x.d5_red_flags,
       to_char(x.fecha, 'YYYY-MM-DD') AS fecha_evaluacion,
       evr.version_rubrica, evr.modelo
FROM lanops.certificados c
JOIN lanops.usuarios us     ON us.id = c.usuario
JOIN lanops.vacantes v      ON v.id = c.vacante
JOIN lanops.empresas em     ON em.id = v.empresa
JOIN lanops.evaluaciones x  ON x.id = c.evaluacion
JOIN lanops.evaluadores evr ON evr.id = x.evaluador
WHERE c.codigo = $1;
