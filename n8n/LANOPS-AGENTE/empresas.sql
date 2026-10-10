-- n8n · workflow LANOPS-AGENTE · nodo "Postgres: empresas"
-- Execute Query · Execute Once ON · Query Parameters: {{ [ JSON.stringify($json.solo) ] }}
-- $1 = lista JSON de nombres (vacía = todas). Empresas activas con página de empleo, sin las de 'ninguna'.
-- robots_url = esquema + dominio de url_empleo + /robots.txt.
SELECT e.id AS empresa, e.nombre, e.url_empleo, e.tipo_lectura, e.ciudad,
       substring(e.url_empleo from '^(https?://[^/?#]+)') || '/robots.txt' AS robots_url
FROM lanops.empresas e
WHERE e.activa AND e.url_empleo IS NOT NULL AND coalesce(e.tipo_lectura, '') <> 'ninguna'
  AND (jsonb_array_length($1::jsonb) = 0 OR e.nombre IN (SELECT jsonb_array_elements_text($1::jsonb)))
ORDER BY e.id;
