# data/ — esquema y datos sintéticos de LANOPS

Fuente única: `esquema.py`. De ahí salen el DDL de Access, el `schema.ini`, el validador y el E-R.

| Archivo | Qué hace |
|---|---|
| `esquema.py` | 13 tablas: campos, tipos, claves, índices, reglas, descripciones |
| `generar_csv.py` | CSV sintéticos con semilla 2026 → `lanops_csv/` (+ `schema.ini`) |
| `validar.py` | Carga los CSV en SQLite con las mismas restricciones y comprueba coherencia |
| `generar_vba.py` | Genera `LANOPS_montaje.bas` (Paso1 crear tablas · Paso2 importar · Paso3 probar) |
| `ddl_access.sql` | El DDL de Access en texto, para leer o explicar |
| `er.py` | Dibuja `docs/LANOPS_ER.png` (necesita graphviz) |

Regenerar todo: `python generar_csv.py && python validar.py && python generar_vba.py && python er.py && neato -Tpng -Gdpi=130 er.dot -o ../docs/LANOPS_ER.png`

La firma de los certificados sintéticos usa un secreto de demostración, no el `CERT_SECRET` real (que solo vive en Railway).
