-- LANOPS-FEEDBACK · requisito en Postgres (una vez). Se pega en n8n → workflow "LANOPS · SQL a mano".
-- Umbral de la opción B (08-oct): descartes por sector de un mismo sector para dejar de enseñarlo.
-- Si se ejecuta dos veces no duplica. Para cambiar el umbral: UPDATE de esta fila (ningún número vive en los nodos).
INSERT INTO lanops.configuracion (clave, valor, descripcion)
VALUES ('descartes_para_excluir_sector', '2',
        'Descartes por motivo sector de un mismo sector para dejar de mostrarlo (LANOPS-FEEDBACK)')
ON CONFLICT (clave) DO NOTHING;
SELECT clave, valor FROM lanops.configuracion WHERE clave = 'descartes_para_excluir_sector';
