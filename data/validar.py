import sqlite3, csv, re, datetime as dt, collections
from esquema import T, COLS
db = sqlite3.connect(":memory:"); db.execute("PRAGMA foreign_keys=ON")
MAP = {"COUNTER": "INTEGER", "LONG": "INTEGER", "SINGLE": "REAL", "DATETIME": "TEXT", "YESNO": "INTEGER", "MEMO": "TEXT"}
for t, desc, cols, cons, extra in T:
    defs = []
    for c in cols:
        ty = MAP.get(c["ddl"], "TEXT"); s = "%s %s%s" % (c["col"] if c["col"] != "global" else '"global"', ty, " NOT NULL" if c["nn"] else "")
        m = re.match(r'In \((.*)\)', c["regla"] or "")
        if m: s += " CHECK (%s IN (%s))" % ('"global"' if c["col"]=="global" else c["col"], m.group(1).replace('"', "'"))
        m = re.match(r'Between (\d) And (\d)', c["regla"] or "")
        if m: s += " CHECK (%s BETWEEN %s AND %s)" % ('"global"' if c["col"]=="global" else c["col"], m.group(1), m.group(2))
        m = re.match(r'Text Width (\d+)', c["ini"])
        if m: s += " CHECK (length(%s) <= %s)" % (c["col"], m.group(1))
        defs.append(s)
    defs += cons
    db.execute("CREATE TABLE %s (%s)" % (t, ", ".join(defs)))
    for x in extra:
        if x.startswith("ALTER"): continue
        db.execute(x)
db.execute("CREATE TABLE _dummy(x)")
def conv(c, v):
    if v == "": return None
    if c["ddl"] in ("LONG", "COUNTER", "YESNO"): return int(v)
    if c["ddl"] == "SINGLE": return float(v.replace(",", "."))
    if c["ddl"] == "DATETIME": dt.datetime.strptime(v, "%d/%m/%Y"); return v
    return v
for t, desc, cols, cons, extra in T:
    rows = list(csv.reader(open("lanops_csv/%s.csv" % t, encoding="utf-8"), delimiter=";"))
    assert rows[0] == COLS[t], t
    for r in rows[1:]:
        assert len(r) == len(cols), (t, r)
        db.execute("INSERT INTO %s VALUES (%s)" % (t, ",".join("?" * len(r))), [conv(c, v) for c, v in zip(cols, r)])
# autorreferencia
bad = db.execute("SELECT count(*) FROM USUARIOS u LEFT JOIN USUARIOS r ON u.recomendado_por=r.id WHERE u.recomendado_por IS NOT NULL AND (r.id IS NULL OR r.id>=u.id)").fetchone()
print("autorref mala", bad)
print("FK check", db.execute("PRAGMA foreign_key_check").fetchall()[:3])
D = lambda s: dt.datetime.strptime(s, "%d/%m/%Y").date(); HOY = dt.date(2026, 9, 25)
q = lambda s: db.execute(s).fetchall()
print("eval antes de alta/pub", sum(1 for f, a, p in q("SELECT e.fecha,u.fecha_alta,v.fecha_pub FROM EVALUACIONES e JOIN USUARIOS u ON u.id=e.usuario JOIN VACANTES v ON v.id=e.vacante") if D(f) < D(a) or D(f) < D(p)))
print("eval > hoy", sum(1 for (f,) in q("SELECT fecha FROM EVALUACIONES") if D(f) > HOY))
print("eval fuera de fecha evaluador", sum(1 for f, fa in q("SELECT e.fecha, v.fecha_alta FROM EVALUACIONES e JOIN EVALUADORES v ON v.id=e.evaluador") if D(f) < D(fa)))
print("cert antes eval", sum(1 for a, b in q("SELECT c.fecha_emision,e.fecha FROM CERTIFICADOS c JOIN EVALUACIONES e ON e.id=c.evaluacion") if D(a) < D(b)))
print("cert eval coherente", q("SELECT count(*) FROM CERTIFICADOS c JOIN EVALUACIONES e ON e.id=c.evaluacion WHERE e.usuario<>c.usuario OR e.vacante<>c.vacante"))
print("cert estado", q("SELECT estado,count(*) FROM CERTIFICADOS GROUP BY estado"), "banda", q("SELECT e.banda,count(*) FROM CERTIFICADOS c JOIN EVALUACIONES e ON e.id=c.evaluacion GROUP BY e.banda"))
print("cert por estado usuario", q("SELECT u.estado_verificacion,count(*) FROM CERTIFICADOS c JOIN USUARIOS u ON u.id=c.usuario GROUP BY 1"))
print("bandas", q("SELECT banda,count(*) FROM EVALUACIONES GROUP BY banda"), q("SELECT evaluador,count(*),round(avg(\"global\"),2) FROM EVALUACIONES GROUP BY evaluador"))
print("anillos", q("SELECT e.anillo,count(*) FROM VACANTES v JOIN EMPRESAS e ON e.id=v.empresa GROUP BY 1"))
print("estados usr", q("SELECT estado_verificacion,count(*) FROM USUARIOS GROUP BY 1"))
print("verif", q("SELECT tipo,estado,count(*) FROM VERIFICACIONES GROUP BY 1,2"))
print("tecnun mail vs verif", q("SELECT count(*) FROM VERIFICACIONES v JOIN USUARIOS u ON u.id=v.usuario WHERE v.tipo='email_institucional' AND u.email NOT LIKE '%@alumni.tecnun.es'"))
print("feedback", q("SELECT veredicto,count(*) FROM FEEDBACK GROUP BY 1"))
print("fuente", q("SELECT fuente,count(*) FROM VACANTES GROUP BY 1"), q("SELECT estado,count(*) FROM VACANTES GROUP BY 1"))
print("explicaciones distintas", q("SELECT count(DISTINCT explicacion), count(DISTINCT hueco) FROM EVALUACIONES"))
print("pares humanos comparables", q("SELECT count(*) FROM EVALUACIONES h JOIN EVALUACIONES i ON h.usuario=i.usuario AND h.vacante=i.vacante WHERE h.evaluador IN (3,4) AND i.evaluador IN (1,2,5)"))
print("ejemplo", q("SELECT u.nombre,v.puesto,e.\"global\",e.explicacion,e.hueco FROM EVALUACIONES e JOIN USUARIOS u ON u.id=e.usuario JOIN VACANTES v ON v.id=e.vacante WHERE e.banda='Alta' LIMIT 2"))
print("ejemplo cv", q("SELECT cv_texto FROM USUARIOS LIMIT 1"))
print("ejemplo vac", q("SELECT puesto,requisitos,ubicacion FROM VACANTES LIMIT 2"))
print("max len memo", q("SELECT max(length(cv_texto)) FROM USUARIOS"), q("SELECT max(length(explicacion)) FROM EVALUACIONES"))
print("semicolon/quote in data", sum(1 for t in COLS for r in open("lanops_csv/%s.csv"%t,encoding="utf-8") if '"' in r))
