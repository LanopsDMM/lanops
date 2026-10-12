-- n8n · workflow LANOPS-LANBIDE · nodo "Postgres: cerrar desaparecidas"
-- Operación: Execute Query · Settings: Execute Once = ON
-- ACTIVO: el JSON trae todas las ofertas gestionadas por Lanbide (5-oct: 700 en el JSON,
-- 698 en la web con origen "Lanbide"). Las de otros orígenes no vienen en el JSON.
-- Salvaguarda: solo cierra si hoy se vio al menos una vacante de Lanbide
-- (si el upsert no corrió hoy, no cierra nada).
-- [12-oct] Además, cada mañana cierra las ofertas PEGADAS (fuente 'usuario') que nadie ha vuelto a pegar en
-- CONFIGURACION.caducidad_oferta_pegada_dias (30): LANOPS no sabe cuándo deja de estar publicada una oferta
-- pegada. Volver a pegarla la reabre (LANOPS-PEGAR-OFERTA actualiza vista_en). Un certificado ya emitido
-- sigue valiendo hasta su propia caducidad. Va en un WITH para que siga siendo una sola sentencia.
WITH pegadas AS (
  UPDATE lanops.vacantes
  SET estado = 'cerrada'
  WHERE fuente = 'usuario'
    AND estado = 'abierta'
    AND coalesce(vista_en, fecha_pub) < now() - make_interval(days => coalesce(
          (SELECT valor::int FROM lanops.configuracion WHERE clave = 'caducidad_oferta_pegada_dias'), 30))
  RETURNING id
)
UPDATE lanops.vacantes
SET estado = 'cerrada'
WHERE fuente = 'lanbide'
  AND estado = 'abierta'
  AND vista_en < CURRENT_DATE
  AND EXISTS (SELECT 1 FROM lanops.vacantes
              WHERE fuente = 'lanbide' AND vista_en = CURRENT_DATE)
RETURNING id;
