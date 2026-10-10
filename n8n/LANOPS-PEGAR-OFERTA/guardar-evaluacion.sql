-- n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Postgres: guardar evaluación"
-- Execute Query · Query Parameters: {{ [ JSON.stringify($json) ] }}
-- Como LANOPS-ENCAJE/insertar.sql para una fila. Si ya había una evaluación de esta vacante con este CV
-- y este evaluador (la misma oferta pegada dos veces), NO se toca (puede tener un certificado firmado
-- con su "global") y se devuelve la existente.
WITH r AS (
  SELECT * FROM jsonb_to_record($1::jsonb) AS x(
    usuario int, vacante int, evaluador int, d1_match_cv int, d2_north_star int, d3_compensacion int,
    d4_cultura int, d5_red_flags int, global real, global_personal real, banda text,
    explicacion text, hueco text, hash_cv text)
),
ins AS (
  INSERT INTO lanops.evaluaciones
    (usuario, vacante, evaluador, fecha, d1_match_cv, d2_north_star, d3_compensacion, d4_cultura,
     d5_red_flags, global, global_personal, banda, explicacion, hueco, hash_cv)
  SELECT usuario, vacante, evaluador, CURRENT_DATE, d1_match_cv, d2_north_star, d3_compensacion,
         d4_cultura, d5_red_flags, global, global_personal, banda, explicacion, hueco, hash_cv
  FROM r
  ON CONFLICT (usuario, vacante, evaluador, hash_cv) DO NOTHING
  RETURNING id, vacante, global, global_personal, banda, d1_match_cv, d2_north_star, d3_compensacion,
            d4_cultura, d5_red_flags, explicacion, hueco, false AS ya_evaluada
)
SELECT * FROM ins
UNION ALL
SELECT e.id, e.vacante, e.global, e.global_personal, e.banda, e.d1_match_cv, e.d2_north_star, e.d3_compensacion,
       e.d4_cultura, e.d5_red_flags, e.explicacion, e.hueco, true AS ya_evaluada
FROM lanops.evaluaciones e JOIN r USING (usuario, vacante, evaluador, hash_cv)
WHERE NOT EXISTS (SELECT 1 FROM ins);
