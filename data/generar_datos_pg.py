# Genera data/datos-sinteticos-personas.sql: carga en Postgres (esquema lanops) los CSV
# sintéticos que describen a las personas (decisión 86, opción A). No carga VACANTES,
# EVALUACIONES, FEEDBACK, CERTIFICADOS ni EMPRESAS: las vacantes de Postgres son las reales de Lanbide.
# Uso: python3 -I generar_datos_pg.py <carpeta data/> <salida .sql>
import csv, os, re, runpy, sys

data, out = sys.argv[1], sys.argv[2]
T = {t[0]: t for t in runpy.run_path(os.path.join(data, 'esquema.py'))['T']}
TABLAS = ['CONFIGURACION', 'ENTIDADES', 'HABILIDADES', 'EVALUADORES', 'USUARIOS',
          'USUARIO_HABILIDAD', 'PREFERENCIAS', 'VERIFICACIONES']

def lit(v, ddl):
    if v is None or v == '': return 'NULL'
    if ddl == 'YESNO': return 'true' if v.strip() in ('-1', '1', 'True', 'Verdadero') else 'false'
    if ddl in ('LONG', 'COUNTER'): return str(int(v))
    if ddl == 'SINGLE': return str(float(v.replace(',', '.')))
    if ddl == 'DATETIME':
        m = re.fullmatch(r'(\d{2})/(\d{2})/(\d{4})(.*)', v.strip())
        if not m: raise ValueError('fecha: ' + v)
        return "'%s-%s-%s%s'" % (m.group(3), m.group(2), m.group(1), m.group(4))
    return "'" + v.replace("'", "''") + "'"

L = ['-- LANOPS · datos sintéticos de personas para Postgres (esquema lanops)',
     '-- Generado desde data/lanops_csv/ con data/generar_datos_pg.py (decisión 86).',
     '-- No incluye VACANTES, EVALUACIONES, FEEDBACK, CERTIFICADOS ni EMPRESAS.',
     '-- Se ejecuta una vez, entero, con el usuario marcos.', '']
cuenta = {}
for t in TABLAS:
    ddl = {c['col']: c['ddl'] for c in T[t][2]}
    with open(os.path.join(data, 'lanops_csv', t + '.csv'), encoding='utf-8-sig', newline='') as f:
        filas = list(csv.DictReader(f, delimiter=';', quotechar='"'))
    cols = list(filas[0].keys())
    assert set(cols) == set(ddl), (t, set(cols) ^ set(ddl))
    vals = ['(' + ', '.join(lit(r[c], ddl[c]) for c in cols) + ')' for r in filas]
    L.append('INSERT INTO lanops.%s (%s) VALUES\n%s;' % (t.lower(), ', '.join(cols), ',\n'.join(vals)))
    if 'COUNTER' in ddl.values():
        L.append("SELECT setval(pg_get_serial_sequence('lanops.%s', 'id'), (SELECT max(id) FROM lanops.%s));"
                 % (t.lower(), t.lower()))
    L.append('')
    cuenta[t] = len(filas)
L.append('SELECT ' + ', '.join("(SELECT count(*) FROM lanops.%s) AS %s" % (t.lower(), t.lower()) for t in TABLAS) + ';')
open(out, 'w', encoding='utf-8').write('\n'.join(L) + '\n')
print(cuenta)
