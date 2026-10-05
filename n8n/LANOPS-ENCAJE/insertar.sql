-- n8n · workflow LANOPS-ENCAJE · nodo "Postgres: guardar evaluaciones"
-- Recibe TODAS las salidas de "Code: leer evaluación" y guarda solo las ok.
-- Execute Query · Execute Once ON · Settings → Always Output Data ON (para que "Postgres: lista" corra aunque no se guarde nada)
-- Query Parameters: {{ [ JSON.stringify($input.all().map(i => i.json)) ] }}
INSERT INTO lanops.evaluaciones
  (usuario, vacante, evaluador, fecha, d1_match_cv, d2_north_star, d3_compensacion, d4_cultura,
   d5_red_flags, global, global_personal, banda, explicacion, hueco, hash_cv)
SELECT r.usuario, r.vacante, r.evaluador, CURRENT_DATE, r.d1_match_cv, r.d2_north_star, r.d3_compensacion,
       r.d4_cultura, r.d5_red_flags, r.global, r.global_personal, r.banda, r.explicacion, r.hueco, r.hash_cv
FROM jsonb_to_recordset($1::jsonb) AS r(
  ok boolean, usuario int, vacante int, evaluador int, d1_match_cv int, d2_north_star int, d3_compensacion int,
  d4_cultura int, d5_red_flags int, global real, global_personal real, banda text,
  explicacion text, hueco text, hash_cv text)
WHERE r.ok
ON CONFLICT (usuario, vacante, evaluador, hash_cv) DO NOTHING
RETURNING id, vacante, global, global_personal, banda;
