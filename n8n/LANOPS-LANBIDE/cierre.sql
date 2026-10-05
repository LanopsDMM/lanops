-- n8n · workflow LANOPS-LANBIDE · nodo "Postgres: cerrar desaparecidas"
-- Operación: Execute Query · Settings: Execute Once = ON
-- ACTIVO: el JSON trae todas las ofertas gestionadas por Lanbide (5-oct: 700 en el JSON,
-- 698 en la web con origen "Lanbide"). Las de otros orígenes no vienen en el JSON.
-- Salvaguarda: solo cierra si hoy se vio al menos una vacante de Lanbide
-- (si el upsert no corrió hoy, no cierra nada).
UPDATE lanops.vacantes
SET estado = 'cerrada'
WHERE fuente = 'lanbide'
  AND estado = 'abierta'
  AND vista_en < CURRENT_DATE
  AND EXISTS (SELECT 1 FROM lanops.vacantes
              WHERE fuente = 'lanbide' AND vista_en = CURRENT_DATE)
RETURNING id;
