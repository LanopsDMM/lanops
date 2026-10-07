-- n8n · workflow LANOPS-VERIFICAR · nodo "Postgres: contar"
-- Execute Query · Execute Once ON · Settings → Always Output Data ON (si no actualiza nada, la respuesta sale igual)
-- Query Parameters: {{ [ $json.contar ? $json.codigo : '', $json.estado_bd || 'vigente' ] }}
-- Suma 1 a veces_verificado y, si la fecha ya pasó, deja el certificado en 'caducado'.
-- Nunca devuelve a 'vigente' un certificado revocado o caducado.
UPDATE lanops.certificados
SET veces_verificado = coalesce(veces_verificado, 0) + 1,
    estado = CASE WHEN estado = 'vigente' AND $2 = 'caducado' THEN 'caducado' ELSE estado END
WHERE codigo = $1
RETURNING codigo, estado, veces_verificado;
