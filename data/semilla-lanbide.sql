-- Semilla mínima para LANOPS-LANBIDE: la empresa comodín a la que se asignan
-- las vacantes de Lanbide (Lanbide no publica el nombre de la empresa).
-- Mismo id (61) que en data/lanops_csv/EMPRESAS.csv: al cargar los CSV, saltar esa fila.
INSERT INTO lanops.empresas (id, nombre, anillo, tipo_lectura, fallos_seguidos, activa)
VALUES (61, '(Lanbide, sin identificar)', 1, 'ninguna', 0, true);
SELECT setval(pg_get_serial_sequence('lanops.empresas', 'id'), 61);
