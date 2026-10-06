# Genera data/schema.sql (Postgres, esquema lanops) a partir de data/esquema.py.
# Uso: python3 -I generar_schema_pg.py <ruta a esquema.py> <salida schema.sql>
import re, runpy, sys

src, out = sys.argv[1], sys.argv[2]
T = runpy.run_path(src)['T']

def tipo(ddl):
    if ddl == 'COUNTER': return 'serial'
    m = re.fullmatch(r'TEXT\((\d+)\)', ddl)
    if m: return 'varchar(%s)' % m.group(1)
    return {'MEMO': 'text', 'LONG': 'integer', 'SINGLE': 'real',
            'YESNO': 'boolean', 'DATETIME': 'timestamp'}[ddl]

def q(s):  # literal SQL
    return "'" + s.replace("'", "''") + "'"

def regla(col, r):
    m = re.fullmatch(r'In \((.*)\)', r)
    if m:
        vals = re.findall(r'"([^"]*)"', m.group(1))
        return '%s IN (%s)' % (col, ', '.join(q(v) for v in vals))
    m = re.fullmatch(r'Between (\S+) And (\S+)', r)
    if m: return '%s BETWEEN %s AND %s' % (col, m.group(1), m.group(2))
    m = re.fullmatch(r'(>=|<=|>|<)\s*(\S+)', r)
    if m: return '%s %s %s' % (col, m.group(1), m.group(2))
    raise ValueError(r)

def defecto(ddl, d):
    if d is None: return None
    if d == 'Date()': return 'CURRENT_DATE'
    if ddl == 'YESNO': return 'true' if d in ('-1', 'True') else 'false'
    if d.startswith('"'): return q(d.strip('"'))
    return d

def calificar(sql):  # USUARIOS -> lanops.usuarios en REFERENCES / ON / ALTER TABLE
    nombres = [t[0] for t in T]
    for n in sorted(nombres, key=len, reverse=True):
        sql = re.sub(r'(REFERENCES|ON|ALTER TABLE)\s+%s\b' % n,
                     lambda m: '%s lanops.%s' % (m.group(1), n.lower()), sql)
    return sql

L = ['-- LANOPS · esquema de Postgres (esquema lanops)',
     '-- Generado desde data/esquema.py (misma estructura que el .mdb de Access).',
     '-- Tablas en minúscula; COUNTER -> serial, TEXT(n) -> varchar(n), MEMO -> text,',
     '-- LONG -> integer, SINGLE -> real, YESNO -> boolean, DATETIME -> timestamp.',
     '-- Reglas de validación de Access -> CHECK. Descripciones -> COMMENT.',
     '-- Se ejecuta con el usuario marcos (dueño del esquema lanops), todo de una vez.',
     '']
for nombre, desc_t, cols, cons, extra in T:
    t = 'lanops.' + nombre.lower()
    filas = []
    for c in cols:
        f = '  %s %s' % (c['col'], tipo(c['ddl']))
        if c['nn'] and c['ddl'] != 'COUNTER': f += ' NOT NULL'
        d = defecto(c['ddl'], c['defecto'])
        if d: f += ' DEFAULT ' + d
        if c['regla']:
            f += ' CONSTRAINT ck_%s_%s CHECK (%s)' % (nombre.lower(), c['col'], regla(c['col'], c['regla']))
        filas.append(f)
    filas += ['  ' + calificar(x) for x in cons]
    L.append('CREATE TABLE %s (\n%s\n);' % (t, ',\n'.join(filas)))
    L.append('COMMENT ON TABLE %s IS %s;' % (t, q(desc_t)))
    for c in cols:
        L.append('COMMENT ON COLUMN %s.%s IS %s;' % (t, c['col'], q(c['desc'])))
    for x in extra:
        L.append(calificar(x) + ';')
    L.append('')
open(out, 'w', encoding='utf-8').write('\n'.join(L))
print('tablas:', len(T))
