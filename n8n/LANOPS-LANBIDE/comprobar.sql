-- Comprobación read-only tras cada ejecución (criterio de cierre de la Pieza 5)
SELECT fuente, estado, COUNT(*) FROM lanops.vacantes GROUP BY fuente, estado ORDER BY 1, 2;
