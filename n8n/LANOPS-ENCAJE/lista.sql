-- n8n · workflow LANOPS-ENCAJE · nodo "Postgres: lista"
-- Execute Query · Execute Once ON · Query Parameters: {{ [ $('Code: entrada').first().json.usuario ] }}
-- Lista del usuario: evaluaciones del evaluador IA activo con su CV actual,
-- sobre vacantes abiertas que no ha descartado, ordenadas por global_personal (decisión 16).
WITH u AS (SELECT id, md5(coalesce(cv_texto, '')) AS hash_cv FROM lanops.usuarios WHERE id = $1),
     ev AS (SELECT id FROM lanops.evaluadores WHERE tipo = 'ia' AND activo)
SELECT x.vacante, v.puesto, e.nombre AS empresa, v.ubicacion, v.url_origen, v.fuente,
       x.global, x.global_personal, x.banda, x.d1_match_cv, x.d2_north_star, x.d3_compensacion,
       x.d4_cultura, x.d5_red_flags, x.explicacion, x.hueco, x.fecha
FROM lanops.evaluaciones x
JOIN u ON x.usuario = u.id AND x.hash_cv = u.hash_cv
JOIN ev ON x.evaluador = ev.id
JOIN lanops.vacantes v ON v.id = x.vacante AND v.estado = 'abierta'
JOIN lanops.empresas e ON e.id = v.empresa
WHERE NOT EXISTS (SELECT 1 FROM lanops.feedback f
                  WHERE f.usuario = u.id AND f.vacante = x.vacante AND f.veredicto = 'descartada')
ORDER BY x.global_personal DESC, x.global DESC
LIMIT 50;
