-- Función auxiliar del esquema lanops (no es una tabla: no toca la estructura congelada).
-- Minúsculas y sin tildes, para comparar "Donostia" con "DONOSTIA/SAN SEBASTIÁN".
CREATE OR REPLACE FUNCTION lanops.norm(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT lower(translate(t, 'ÁÉÍÓÚÜÑáéíóúüñÀÈÌÒÙàèìòù', 'AEIOUUNaeiouunAEIOUaeiou'))
$$;
