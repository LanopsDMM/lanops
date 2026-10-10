-- n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Postgres: contexto"
-- Execute Query · Query Parameters: {{ [ $('Code: entrada').first().json.usuario ] }}
-- Igual que LANOPS-ENCAJE/contexto.sql: CV, preferencias, evaluador IA activo y umbrales de banda.
SELECT u.id AS usuario,
       u.cv_texto,
       md5(coalesce(u.cv_texto, '')) AS hash_cv,
       coalesce((SELECT json_agg(json_build_object('tipo', p.tipo, 'clave', p.clave, 'valor', p.valor, 'peso', p.peso)
                                 ORDER BY p.tipo, p.clave)
                 FROM lanops.preferencias p WHERE p.usuario = u.id), '[]'::json) AS preferencias,
       ev.id AS evaluador, ev.modelo, ev.prompt,
       (SELECT valor::numeric FROM lanops.configuracion WHERE clave = 'umbral_banda_alta')  AS umbral_alta,
       (SELECT valor::numeric FROM lanops.configuracion WHERE clave = 'umbral_banda_media') AS umbral_media
FROM lanops.usuarios u
CROSS JOIN (SELECT id, modelo, prompt FROM lanops.evaluadores WHERE tipo = 'ia' AND activo LIMIT 1) ev
WHERE u.id = $1;
