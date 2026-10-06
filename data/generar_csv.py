"""Genera los CSV sintéticos de LANOPS (semilla fija 2026) + schema.ini.
Mismos datos para Access (.mdb) y Postgres. Uso: python generar_csv.py  -> carpeta lanops_csv/"""
import random, hashlib, hmac, uuid, csv, os, datetime as dt
from esquema import T, COLS
R = random.Random(2026)
HOY = dt.date(2026, 9, 25)
SECRETO_DEMO = b"LANOPS-DEMO-NO-ES-EL-SECRETO-REAL"   # el real vive solo en Railway (CERT_SECRET)
d = lambda s: dt.datetime.strptime(s, "%d/%m/%Y").date()
f = lambda x: x.strftime("%d/%m/%Y") if x else ""
md5 = lambda s: hashlib.md5(s.encode()).hexdigest()
def dia(a, b): return a + dt.timedelta(days=R.randint(0, max(0, (b - a).days)))
def dec(x): return ("%.1f" % x).replace(".", ",")
OUT = {t[0]: [] for t in T}

# ---------- CONFIGURACION
for k, v, ds in [("cupo_recomendaciones", "3", "Recomendaciones que puede hacer cada usuario"),
                 ("caducidad_certificado_dias", "30", "Días hasta que caduca un certificado"),
                 ("reevaluar_si_dias", "7", "Si la evaluación tiene más días, se reevalúa antes de certificar"),
                 ("cierre_agente_dias", "14", "Días sin ver una vacante del agente para cerrarla"),
                 ("umbral_banda_alta", "4", "Global mínima para banda Alta"),
                 ("umbral_banda_media", "3", "Global mínima para banda Media"),
                 ("max_evaluaciones_por_ejecucion", "20", "Tope de evaluaciones con Claude por ejecución de LANOPS-ENCAJE")]:
    OUT["CONFIGURACION"].append([k, v, ds])

# ---------- ENTIDADES
ENT = [(1, "Tecnun", "universidad", "alumni.tecnun.es", "Oficina de carrera Tecnun"),
       (2, "EKINN Harrera", "social", "", "programa@ekinnharrera.eus"),
       (3, "Cruz Roja Gipuzkoa", "social", "", "empleo@cruzrojagipuzkoa.es"),
       (4, "Cáritas Gipuzkoa", "social", "", "insercion@caritasgipuzkoa.org"),
       (5, "Lanbide - Lehen Aukera", "publica", "", "lehenaukera@lanbide.eus")]
for e in ENT: OUT["ENTIDADES"].append(list(e) + [-1])
APROBADOR = {1: "Oficina de carrera Tecnun", 2: "Técnica EKINN", 3: "Cruz Roja - Empleo", 4: "Cáritas - Inserción", 5: "Lanbide - Lehen Aukera"}

# ---------- HABILIDADES
HAB = {"tecnica": ["Python", "SQL", "Java", "JavaScript", "React", "Contabilidad", "Diseño gráfico", "Redes", "Ciberseguridad",
                   "Machine learning", "Gestión de proyectos", "Logística", "Soldadura", "Mecanizado CNC", "Prevención de riesgos", "Análisis estadístico"],
       "idioma": ["Euskera", "Inglés", "Francés", "Alemán"],
       "transversal": ["Trabajo en equipo", "Comunicación", "Resolución de problemas", "Pensamiento crítico", "Liderazgo", "Adaptabilidad",
                       "Organización", "Atención al cliente", "Negociación", "Proactividad", "Orientación a resultados", "Creatividad", "Empatía",
                       "Gestión del tiempo", "Autonomía", "Flexibilidad", "Trabajo bajo presión", "Vocación de servicio", "Ética profesional",
                       "Iniciativa", "Atención al detalle"],
       "herramienta": ["Excel avanzado", "Power BI", "AutoCAD", "Microsoft Office", "SAP", "Salesforce", "Jira", "Figma", "Photoshop", "WordPress",
                       "Google Analytics", "Odoo", "n8n", "Access", "Git", "Docker", "Tableau", "QuickBooks", "HubSpot"]}
HID = {}
for cat, lst in HAB.items():
    for n in lst:
        HID[n] = len(HID) + 1; OUT["HABILIDADES"].append([HID[n], n, cat])
assert len(HID) == 60
TRANSV = HAB["transversal"]

# ---------- EVALUADORES
EVA = [(1, "Motor LANOPS IA", "ia", "oferta-2026-09", "claude (versión congelada el día 8)", "modes/_shared.md + modes/oferta.md del fork LanopsDMM/motor, congelados el 08/09/2026", -1, "08/09/2026"),
       (2, "Motor LANOPS IA (previo)", "ia", "oferta-2026-08", "claude (versión anterior)", "Versión anterior a la congelación del día 8", 0, "20/08/2026"),
       (3, "Comité de admisión Tecnun", "humano", "manual-tecnun-v1", "", "Revisión manual de casos puntuales para comparar con el motor", -1, "01/07/2026"),
       (4, "Oficina de carrera", "humano", "manual-oc-v1", "", "Revisión manual de casos derivados para comparar con el motor", -1, "01/07/2026"),
       (5, "Motor LANOPS IA (piloto)", "ia", "oferta-2026-07-piloto", "claude (piloto interno)", "Versión de piloto interno, descartada", 0, "15/07/2026")]
for e in EVA: OUT["EVALUADORES"].append(list(e))
def evaluador_ia(fecha):
    return 5 if fecha < dt.date(2026, 8, 20) else 2 if fecha < dt.date(2026, 9, 8) else 1

# ---------- PUESTOS (sector, titulaciones afines, habilidades pedidas, banda salarial)
FP = "FP Grado Superior"; FPM = "FP Grado Medio"
P = {
 "Ingeniero/a de procesos": (["industria"], ["Ingeniería Industrial", "Ingeniería Mecánica"], ["Gestión de proyectos", "Excel avanzado", "SAP", "Resolución de problemas", "AutoCAD"], (28000, 38000)),
 "Técnico/a de mantenimiento": (["industria", "logistica"], [FP, FPM, "Ingeniería Mecánica"], ["Mecanizado CNC", "Prevención de riesgos", "Resolución de problemas", "Autonomía"], (22000, 28000)),
 "Operario/a de producción": (["industria"], ["", FPM], ["Prevención de riesgos", "Trabajo en equipo", "Trabajo bajo presión", "Mecanizado CNC"], (18000, 22000)),
 "Soldador/a": (["industria", "construccion"], [FPM, FP, ""], ["Soldadura", "Prevención de riesgos", "Autonomía"], (21000, 26000)),
 "Técnico/a de calidad": (["industria"], ["Ingeniería Industrial", "Química", FP], ["Excel avanzado", "SAP", "Pensamiento crítico", "Atención al detalle"], (24000, 30000)),
 "Delineante": (["construccion", "industria"], [FP, "Arquitectura"], ["AutoCAD", "Diseño gráfico", "Atención al detalle"], (21000, 26000)),
 "Arquitecto/a técnico/a": (["construccion"], ["Arquitectura"], ["AutoCAD", "Gestión de proyectos", "Negociación", "Prevención de riesgos"], (26000, 32000)),
 "Almacenero/a": (["logistica", "comercio"], ["", FPM], ["Logística", "SAP", "Trabajo en equipo"], (18000, 21000)),
 "Técnico/a de logística": (["logistica"], ["ADE", FP], ["Logística", "SAP", "Excel avanzado", "Organización"], (22000, 28000)),
 "Analista de datos": (["tecnologia", "finanzas", "consultoria"], ["Ingeniería Informática", "Economía", "Física", "Ingeniería Industrial"], ["Python", "SQL", "Power BI", "Análisis estadístico", "Excel avanzado"], (28000, 36000)),
 "Programador/a junior": (["tecnologia"], ["Ingeniería Informática", "Telecomunicaciones", FP], ["Java", "JavaScript", "Git", "SQL"], (24000, 30000)),
 "Desarrollador/a backend": (["tecnologia"], ["Ingeniería Informática", "Telecomunicaciones"], ["Python", "SQL", "Docker", "Git"], (28000, 36000)),
 "Administrador/a de sistemas": (["tecnologia"], ["Telecomunicaciones", "Ingeniería Informática", FP], ["Redes", "Ciberseguridad", "Docker"], (26000, 32000)),
 "Diseñador/a UX": (["tecnologia", "comercio"], ["Diseño", "Marketing"], ["Figma", "Photoshop", "Creatividad", "Empatía"], (24000, 30000)),
 "Auxiliar contable": (["finanzas", "consultoria"], ["ADE", "Economía", FP], ["Contabilidad", "Excel avanzado", "QuickBooks", "Organización"], (20000, 24000)),
 "Analista financiero/a": (["finanzas"], ["ADE", "Economía"], ["Excel avanzado", "Power BI", "Contabilidad", "Pensamiento crítico"], (28000, 35000)),
 "Consultor/a junior": (["consultoria"], ["ADE", "Derecho", "Ingeniería Industrial", "Economía"], ["Gestión de proyectos", "Comunicación", "Excel avanzado", "Inglés"], (26000, 32000)),
 "Técnico/a de RRHH": (["consultoria", "educacion"], ["Psicología", "Derecho"], ["Comunicación", "Empatía", "Microsoft Office", "Negociación"], (22000, 27000)),
 "Comercial": (["comercio", "logistica", "industria"], ["ADE", "Marketing", ""], ["Negociación", "Atención al cliente", "Salesforce", "Orientación a resultados"], (20000, 26000)),
 "Técnico/a de marketing digital": (["comercio", "consultoria"], ["Marketing", "Diseño"], ["Google Analytics", "WordPress", "HubSpot", "Creatividad"], (22000, 27000)),
 "Dependiente/a": (["comercio"], ["", FPM], ["Atención al cliente", "Vocación de servicio", "Trabajo en equipo"], (17000, 19000)),
 "Camarero/a": (["hosteleria"], ["", FPM], ["Atención al cliente", "Trabajo bajo presión", "Euskera", "Inglés"], (17000, 19000)),
 "Recepcionista": (["hosteleria", "salud"], ["", FP], ["Atención al cliente", "Inglés", "Francés", "Microsoft Office"], (18000, 21000)),
 "Cocinero/a": (["hosteleria"], [FPM, FP], ["Trabajo bajo presión", "Organización", "Creatividad"], (19000, 23000)),
 "Técnico/a de laboratorio": (["salud"], ["Biología", "Química"], ["Análisis estadístico", "Pensamiento crítico", "Atención al detalle", "Inglés"], (22000, 27000)),
 "Auxiliar de enfermería": (["salud"], [FPM], ["Empatía", "Atención al cliente", "Trabajo bajo presión"], (19000, 22000)),
 "Administrativo/a": (["industria", "logistica", "construccion", "finanzas", "consultoria", "comercio", "salud", "educacion"], [FP, "ADE", "Derecho", ""], ["Microsoft Office", "Organización", "Odoo", "Atención al cliente"], (18000, 22000)),
 "Educador/a": (["educacion"], ["Psicología", "Magisterio"], ["Empatía", "Comunicación", "Euskera", "Creatividad"], (21000, 25000)),
 "Asesor/a jurídico/a junior": (["consultoria", "finanzas"], ["Derecho"], ["Negociación", "Pensamiento crítico", "Comunicación", "Inglés"], (24000, 30000)),
}
for p in P.values():
    for h in p[2]: assert h in HID, h
POR_SECTOR = {}
for pu, (secs, *_ ) in P.items():
    for s in secs: POR_SECTOR.setdefault(s, []).append(pu)

TITULACIONES = ["Ingeniería Industrial", "Ingeniería Mecánica", "Ingeniería Informática", "Telecomunicaciones", "ADE", "Economía", "Derecho",
                "Arquitectura", "Marketing", "Biología", "Química", "Psicología", "Física", "Magisterio", "Diseño", FP, FPM, ""]
TIT_PESO = [14, 8, 14, 8, 16, 10, 10, 8, 10, 6, 5, 9, 5, 6, 5, 20, 12, 14]
TECNUN = {"Ingeniería Industrial", "Ingeniería Mecánica", "Ingeniería Informática", "Telecomunicaciones", "Física", "Química"}
POOL = {t: sorted({h for pu, (s, tits, hs, b) in P.items() if t in tits for h in hs} - set(HAB["idioma"])) for t in TITULACIONES}

GIPUZKOA = ["Donostia", "Irun", "Errenteria", "Eibar", "Zarautz", "Arrasate", "Hernani", "Tolosa", "Lasarte-Oria", "Bergara", "Andoain",
            "Azpeitia", "Beasain", "Oñati", "Pasaia", "Hondarribia", "Azkoitia", "Zumarraga", "Legazpi", "Ordizia"]
GP = [30, 10, 7, 5, 5, 5, 5, 5, 5, 4, 4, 3, 3, 3, 3, 3, 2, 2, 2, 2]

# ---------- EMPRESAS
APELL = ["Arregi", "Otegi", "Etxeberria", "Mendizabal", "Urrutia", "Agirre", "Zubizarreta", "Aizpurua", "Larrañaga", "Garmendia", "Iturriaga",
         "Elizondo", "Lasa", "Olano", "Irazabal", "Ugarte", "Uranga", "Goikoetxea", "Beristain", "Zabaleta", "Azkue", "Echave", "Sarasola", "Ibarguren"]
PREF = {"industria": ["Talleres", "Mecanizados", "Fundiciones", "Troqueles"], "logistica": ["Transportes", "Logística"],
        "construccion": ["Construcciones", "Estructuras"], "tecnologia": ["Sistemas", "Software"], "finanzas": ["Asesoría", "Gestoría"],
        "consultoria": ["Consultoría"], "comercio": ["Comercial", "Suministros"], "hosteleria": ["Restaurante", "Hotel"],
        "salud": ["Clínica", "Laboratorios"], "educacion": ["Academia", "Centro de formación"]}
SECT = ["industria"] * 14 + ["logistica"] * 7 + ["construccion"] * 6 + ["tecnologia"] * 7 + ["finanzas"] * 5 + ["consultoria"] * 5 + \
       ["comercio"] * 5 + ["hosteleria"] * 5 + ["salud"] * 4 + ["educacion"] * 2
assert len(SECT) == 60
R.shuffle(SECT)
FUERA = {i: c for i, c in zip(R.sample(range(1, 61), 8), ["Madrid"] * 5 + ["Bilbao", "Pamplona", "Barcelona"])}
LECT = ["ats"] * 9 + ["jsonld"] * 5 + ["html"] * 9 + ["manual"] * 4 + ["pdf"] * 2 + ["ninguna"] * 31
R.shuffle(LECT)
nombres_emp = set(); EMP = {}
for i in range(1, 61):
    s = SECT[i - 1]
    while True:
        n = "%s %s" % (R.choice(PREF[s]), R.choice(APELL))
        if R.random() < 0.3: n += " S. Coop."
        if n not in nombres_emp: break
    nombres_emp.add(n)
    ciudad = FUERA.get(i) or R.choices(GIPUZKOA, GP)[0]
    anillo = 2 if ciudad == "Madrid" else 3 if i in FUERA else 1
    slug = n.lower().replace(" s. coop.", "").replace(" ", "").replace("í", "i").replace("ñ", "n").replace("ó", "o").replace("é", "e")
    lec = LECT[i - 1]
    web = "https://www.%s.example" % slug
    emp_url = "" if lec == "ninguna" else web + ("/empleo/ofertas.pdf" if lec == "pdf" else "/empleo")
    ult = dia(dt.date(2026, 9, 18), dt.date(2026, 9, 24)) if lec in ("ats", "jsonld", "html") else None
    EMP[i] = dict(sector=s, ciudad=ciudad, anillo=anillo, lec=lec, url=emp_url, slug=slug)
    OUT["EMPRESAS"].append([i, n, s, ciudad, anillo, R.choices(["micro", "pequeña", "mediana", "grande"], [3, 5, 5, 3])[0],
                            web, emp_url, lec, f(ult), 0, -1])
for i in R.sample([k for k, v in EMP.items() if v["lec"] in ("html", "jsonld")], 2): OUT["EMPRESAS"][i - 1][10] = R.choice([2, 3])
OUT["EMPRESAS"][R.choice([k for k, v in EMP.items() if v["lec"] == "ninguna"]) - 1][11] = 0
OUT["EMPRESAS"].append([61, "(Lanbide, sin identificar)", "", "", 1, "", "", "", "ninguna", "", 0, -1])
PLACE = 61

# ---------- USUARIOS
NOM = ["Izaro", "Ane", "Maialen", "Nerea", "Amaia", "Leire", "Uxue", "Irati", "June", "Lucía", "Sara", "Marta", "Paula", "Laura", "Fatima",
       "Mariana", "Valentina", "Aitor", "Unai", "Iker", "Jon", "Mikel", "Asier", "Ander", "Gorka", "Pablo", "Daniel", "Hugo", "Carlos",
       "Youssef", "Omar", "Diego", "Santiago", "Andrés", "Kevin", "Nicolás", "Bilal", "Adama", "Ioana", "Camila"]
APU = APELL + ["García", "Fernández", "López", "Martínez", "Sánchez", "Pérez", "Romero", "Díaz", "Ruiz", "Moreno", "Castillo", "Rojas",
               "Benali", "El Amrani", "Popescu", "Diallo", "Mendoza", "Vargas", "Herrera", "Silva"]
ascii_ = lambda s: s.lower().translate(str.maketrans("áéíóúñü ", "aeiounu."))
alta = sorted(dia(dt.date(2026, 6, 1), dt.date(2026, 9, 22)) for _ in range(200))
ESTADOS = ["sin_verificar"] * 85 + ["pendiente"] * 25 + ["verificado"] * 80 + ["revocado"] * 10
R.shuffle(ESTADOS)
U = {}; emails = set(); cupo = {}
for i in range(1, 201):
    n, a = R.choice(NOM), R.choice(APU)
    tit = R.choices(TITULACIONES, TIT_PESO)[0]
    est = ESTADOS[i - 1]
    via_tecnun = est != "sin_verificar" and tit in TECNUN and R.random() < 0.8
    dom = "alumni.tecnun.es" if via_tecnun else R.choice(["gmail.com", "gmail.com", "hotmail.com", "outlook.es", "yahoo.es"])
    base = "%s.%s" % (ascii_(n), ascii_(a)); k = 1; em = "%s@%s" % (base, dom)
    while em in emails: k += 1; em = "%s%d@%s" % (base, k, dom)
    emails.add(em)
    rec = ""
    if i > 5 and R.random() < 0.4:
        cands = [j for j in range(1, i) if cupo.get(j, 0) < 3 and alta[j - 1] <= alta[i - 1]]
        if cands: rec = R.choice(cands); cupo[rec] = cupo.get(rec, 0) + 1
    U[i] = dict(nombre="%s %s" % (n, a), tit=tit, ciudad=R.choices(GIPUZKOA, GP)[0], est=est, tecnun=via_tecnun, alta=alta[i - 1],
                rec=rec, email=em, exp=R.choices([1, 2, 3, 4, 5], [30, 30, 20, 12, 8])[0])

# habilidades por usuario
UH = {}
for i, u in U.items():
    hs = {}
    pool = POOL[u["tit"]]
    for h in R.sample(pool, min(len(pool), R.randint(3, 5))): hs[h] = R.choices([2, 3, 4, 5], [15, 35, 35, 15])[0]
    if R.random() < 0.6: hs["Euskera"] = R.choices([2, 3, 4, 5], [20, 25, 30, 25])[0]
    if R.random() < 0.75: hs["Inglés"] = R.choices([1, 2, 3, 4, 5], [10, 25, 35, 20, 10])[0]
    if R.random() < 0.15: hs[R.choice(["Francés", "Alemán"])] = R.randint(1, 4)
    for h in R.sample(TRANSV, R.randint(1, 3)): hs.setdefault(h, R.randint(2, 5))
    if R.random() < 0.3:
        h = R.choice(list(HID)); hs.setdefault(h, R.randint(1, 3))
    UH[i] = hs
    for h, l in sorted(hs.items(), key=lambda x: HID[x[0]]): OUT["USUARIO_HABILIDAD"].append([i, HID[h], l])

# ---------- PREFERENCIAS
PREFS = {}
def pref(u, tipo, clave, valor, peso=""):
    key = (u, tipo, clave, str(valor))
    if key in PREFS: return
    PREFS[key] = [u, tipo, clave, str(valor), peso, f(dia(U[u]["alta"], min(HOY, U[u]["alta"] + dt.timedelta(days=20))))]
SECTORES = list(PREF)
for i, u in U.items():
    u["salmin"] = None; u["sec_peso"] = {}
    pref(i, "duro", "municipio", u["ciudad"])
    if R.random() < 0.85: pref(i, "duro", "radio_km", R.choice([10, 20, 30, 50]))
    if R.random() < 0.6: pref(i, "duro", "jornada", R.choice(["completa", "parcial", "indiferente"]))
    if R.random() < 0.5: pref(i, "duro", "contrato", R.choice(["indefinido", "temporal", "practicas"]))
    if R.random() < 0.75:
        u["salmin"] = R.randrange(16000, 33000, 1000); pref(i, "duro", "salario_min", u["salmin"])
    if R.random() < 0.45: pref(i, "duro", "modalidad", R.choice(["presencial", "hibrida", "remoto"]))
    if R.random() < 0.35: pref(i, "duro", "euskera", R.choice(["A2", "B1", "B2", "C1"]))
    if R.random() < 0.3: pref(i, "duro", "fecha_inicio_max", f(u["alta"] + dt.timedelta(days=R.choice([30, 60, 90]))))
    if R.random() < 0.2: pref(i, "duro", "permiso_trabajo", "si")
    pref(i, "duro", "situacion_actual", R.choices(["estudiante", "recien_graduado", "desempleado", "empleado"], [30, 30, 25, 15])[0])
    if R.random() < 0.5: pref(i, "duro", "turnos", R.choice(["si", "no"]))
    for s in R.sample(SECTORES, R.randint(1, 3)):
        w = R.randint(2, 5); u["sec_peso"][s] = w; pref(i, "peso", "sector", s, w)
    if R.random() < 0.6: pref(i, "peso", "tamano", R.choice(["pequeña", "mediana", "grande"]), R.randint(1, 5))
    if R.random() < 0.5: pref(i, "peso", "idioma", "ingles", R.randint(1, 5))
    if R.random() < 0.6: pref(i, "peso", "estabilidad", "indefinido", R.randint(2, 5))
    if R.random() < 0.5: pref(i, "peso", "movilidad", R.choice(["coche", "transporte_publico", "bici"]), R.randint(1, 5))
    if R.random() < 0.7:
        cand = [p for p, v in P.items() if u["tit"] in v[1]] or list(P)
        pref(i, "peso", "puesto_objetivo", R.choice(cand), R.randint(3, 5))
    if R.random() < 0.4: pref(i, "exclusion", "ett", "si")
    if R.random() < 0.35: pref(i, "exclusion", "palabra", R.choice(["comisiones", "turno de noche", "fines de semana", "autónomo"]))
    if R.random() < 0.3: pref(i, "exclusion", "sector", R.choice(SECTORES))
    if R.random() < 0.2: pref(i, "exclusion", "empresa", R.randint(1, 60))
for n, row in enumerate(PREFS.values(), 1): OUT["PREFERENCIAS"].append([n] + row)

# CV texto (después de habilidades y preferencias)
for i, u in U.items():
    hs = UH[i]
    tec = ", ".join("%s (%d)" % (h, l) for h, l in hs.items() if h not in HAB["idioma"] and h not in TRANSV)
    idi = ", ".join("%s (%d)" % (h, l) for h, l in hs.items() if h in HAB["idioma"]) or "no declara"
    tra = ", ".join(h for h in hs if h in TRANSV)
    expd = {1: "sin experiencia laboral", 2: "prácticas o menos de un año de experiencia", 3: "entre uno y dos años de experiencia",
            4: "entre tres y cinco años de experiencia", 5: "más de cinco años de experiencia"}[u["exp"]]
    u["cv"] = "%s. %s. Reside en %s. %s. Habilidades: %s. Idiomas: %s. Competencias: %s." % (
        u["nombre"], ("Titulación: " + u["tit"]) if u["tit"] else "Sin titulación reglada", u["ciudad"], expd.capitalize(), tec or "no declara", idi, tra)
    u["hcv"] = md5(u["cv"])
    OUT["USUARIOS"].append([i, u["nombre"], u["email"], u["ciudad"], u["tit"], u["est"], u["rec"], R.choices([-1, 0], [75, 25])[0],
                            f(u["alta"]), f(u["alta"]), u["cv"]])

# ---------- VERIFICACIONES
V_ = []
for i, u in U.items():
    if u["est"] == "sin_verificar": continue
    fe = dia(u["alta"], min(HOY, u["alta"] + dt.timedelta(days=10)))
    if u["tecnun"]:
        ent, tipo, por = 1, "email_institucional", "sistema"
    else:
        ent = R.choices([1, 2, 3, 4, 5], [10, 30, 20, 20, 20])[0]
        tipo = "documental" if ent == 1 else R.choice(["aval", "aval", "documental"])
        por = APROBADOR[ent]
    if u["est"] == "verificado" and not u["tecnun"] and R.random() < 0.15:
        V_.append([i, ent, "documental", f(u["alta"]), "rechazada", "Equipo LANOPS"])
        fe = dia(fe, min(HOY, fe + dt.timedelta(days=7)))
        tipo = "aval"
    estado = {"verificado": "aprobada", "pendiente": "pendiente", "revocado": "revocada"}[u["est"]]
    V_.append([i, ent, tipo, f(fe), estado, "" if estado == "pendiente" else por])
    u["verif"] = (ENT[ent - 1][1], fe)
for n, row in enumerate(V_, 1): OUT["VERIFICACIONES"].append([n] + row)

# ---------- VACANTES
FUENTES = ["lanbide"] * 105 + ["usuario"] * 45 + ["agente"] * 40 + ["api"] * 32 + ["manual"] * 28
R.shuffle(FUENTES)
ATS = [k for k, v in EMP.items() if v["lec"] == "ats"]; AGE = [k for k, v in EMP.items() if v["lec"] in ("html", "jsonld")]
MAN = [k for k, v in EMP.items() if v["lec"] in ("manual", "pdf")] + [k for k, v in EMP.items() if v["lec"] == "ninguna"]
VAC = {}; hashes = set(); lb = 0
for i, fu in enumerate(FUENTES, 1):
    for intento in range(80):
        if intento == 60: fu = "usuario"   # combinaciones agotadas: pasa a oferta pegada por el usuario
        if fu == "lanbide": emp = PLACE if R.random() < 0.7 else R.randint(1, 60)
        elif fu == "api": emp = R.choice(ATS)
        elif fu == "agente": emp = R.choice(AGE)
        elif fu == "manual": emp = R.choice(MAN)
        else: emp = R.randint(1, 60)
        sec = EMP[emp]["sector"] if emp != PLACE else R.choice(SECTORES)
        pu = R.choice(POR_SECTOR[sec])
        ub = EMP[emp]["ciudad"] if emp != PLACE else R.choices(GIPUZKOA, GP)[0]
        if fu == "lanbide": lb += 1; cod = "LB%06d" % (400000 + lb); h = md5(cod)
        else: cod = ("GH-%d" % (70000 + i)) if fu == "api" else ""; h = md5("%d|%s|%s" % (emp, pu.lower(), ub.lower()))
        if h not in hashes: break
        if fu == "lanbide": lb -= 1
    assert h not in hashes
    hashes.add(h)
    secs, tits, hs, (smin, smax) = P[pu]
    contrato = R.choices(["indefinido", "temporal", "practicas", "otro"], [35, 30, 20, 15])[0]
    if contrato == "practicas": sal = R.randrange(9000, 15001, 500)
    else: sal = R.randrange(smin, smax + 1, 500)
    if R.random() < 0.2: sal = ""
    req_hs = R.sample(hs, min(len(hs), R.randint(3, 4)))
    imp, val = req_hs[:2], req_hs[2:]
    txt = "Se requiere %s." % " y ".join(imp)
    if val: txt += " Se valora %s." % " y ".join(val)
    tit_req = [t for t in tits if t]
    if tit_req and R.random() < 0.7: txt += " Formación: %s." % " o ".join(tit_req[:2])
    if ub in GIPUZKOA and R.random() < 0.3 and "Euskera" not in req_hs:
        txt += " Euskera valorable."; req_hs.append("Euskera")
    txt += " Puesto en %s." % ub
    pub = dia(dt.date(2026, 5, 1), dt.date(2026, 9, 24))
    cerrada = R.random() < 0.2 and (HOY - pub).days > 30
    vista = dia(pub, HOY - dt.timedelta(days=15)) if cerrada else dia(max(pub, HOY - dt.timedelta(days=6)), HOY)
    url = {"lanbide": "https://lanbide.example/oferta/%s" % cod, "api": "https://boards.example/%s/jobs/%d" % (EMP.get(emp, {}).get("slug", "x"), 70000 + i),
           "agente": EMP.get(emp, {}).get("url", ""), "usuario": "https://portal.example/oferta/%d" % (900000 + i) if R.random() < 0.8 else "", "manual": ""}[fu]
    VAC[i] = dict(emp=emp, pu=pu, req=req_hs, tits=tits, sal=sal, pub=pub, vista=vista, cerrada=cerrada, sector=sec, contrato=contrato)
    OUT["VACANTES"].append([i, emp, pu, txt, contrato, R.choices(["completa", "parcial", "indiferente"], [60, 20, 20])[0], ub, sal,
                            "cerrada" if cerrada else "abierta", fu, url, cod, h, f(pub), f(vista)])

# ---------- EVALUACIONES (IA)
def puntuar(ui, vi, ruido=0.0):
    u, v = U[ui], VAC[vi]; hs = UH[ui]
    cover = sum(hs.get(h, 0) / 5 for h in v["req"]) / len(v["req"])
    d2 = round(1 + 4 * cover + R.gauss(0, 0.4 + ruido))
    if u["tit"] in v["tits"]: d1 = 5 if u["tit"] else 4
    elif any(t in TECNUN for t in v["tits"]) and u["tit"] in TECNUN: d1 = 3
    else: d1 = 2 if u["tit"] else 1
    d1 = round(d1 + R.gauss(0, 0.5 + ruido))
    need = 1 if v["contrato"] == "practicas" else 2 if (v["sal"] or 20000) < 24000 else 3
    d3 = round(3 + (u["exp"] - need) + R.gauss(0, 0.6 + ruido))
    if v["sal"] == "" or u["salmin"] is None: d4 = 3
    else:
        gap = v["sal"] - u["salmin"]
        d4 = 5 if gap >= 3000 else 4 if gap >= 0 else 3 if gap >= -3000 else 2 if gap >= -6000 else 1
    d4 = round(d4 + R.gauss(0, 0.3 + ruido))
    cl = lambda x: max(1, min(5, int(x)))
    d1, d2, d3, d4 = cl(d1), cl(d2), cl(d3), cl(d4)
    d5 = cl(round((d1 + 2 * d2 + d3) / 4 + R.gauss(0, 0.5)))
    g = max(1.0, min(5.0, round(0.25 * d1 + 0.35 * d2 + 0.1 * d3 + 0.1 * d4 + 0.2 * d5 + 0.7 + R.gauss(0, 0.25), 1)))
    gp = g + 0.1 * (u["sec_peso"].get(v["sector"], 0) - 2)
    gp = max(1.0, min(5.0, round(gp + R.gauss(0, 0.15), 1)))
    return [d1, d2, d3, d4, d5], g, gp
def banda(g): return "Alta" if g >= 4 else "Media" if g >= 3 else "Baja"
NOMD = ["encaje con el rol", "habilidades pedidas", "experiencia", "retribución", "probabilidad de entrevista"]
def textos(ui, vi, ds, g):
    hs, v = UH[ui], VAC[vi]
    tiene = [h for h in v["req"] if hs.get(h, 0) >= 3]; falta = [h for h in v["req"] if hs.get(h, 0) == 0]; flojo = [h for h in v["req"] if 0 < hs.get(h, 0) < 3]
    fuerte = NOMD[max(range(5), key=lambda k: ds[k])]; debil = NOMD[min(range(5), key=lambda k: ds[k])]
    l1 = "Punto fuerte: %s%s." % (fuerte, (" (" + ", ".join(tiene[:2]) + ")") if tiene and fuerte == "habilidades pedidas" else "")
    if max(ds) < 3: l1 = "Sin puntos fuertes claros para este puesto."
    l2 = ("Cubre %s." % ", ".join(tiene[:3])) if tiene else "No acredita a buen nivel ninguna de las habilidades pedidas."
    l3 = "Punto débil: %s%s." % (debil, (": le falta " + ", ".join(falta[:2])) if falta and debil == "habilidades pedidas" else "")
    if falta: hueco = "Acreditar %s: la vacante lo pide y no figura en el CV." % falta[0]
    elif flojo: hueco = "Subir %s de nivel %d a %d." % (flojo[0], hs[flojo[0]], hs[flojo[0]] + 1)
    elif ds[3] <= 2: hueco = "La retribución queda por debajo de su mínimo: solo compensa si prioriza la experiencia."
    elif ds[2] <= 2: hueco = "Sumar experiencia práctica en el sector (prácticas o proyecto)."
    else: hueco = "Pocas mejoras posibles: preparar la entrevista."
    if min(ds) >= 4: l3 = "Sin puntos débiles relevantes."
    return " ".join([l1, l2, l3]), hueco
EV = []; pares = set(); EV_POR_PAR = {}
AFINES = {i: [vi for vi, v in VAC.items() if U[i]["tit"] in v["tits"] or v["sector"] in U[i]["sec_peso"]] for i in U}
while len(EV) < 3000:
    ui = R.randint(1, 200)
    # el motor prefiltra en SQL (titulación, sector preferido); una parte entra por "pegar oferta" o exploración
    vi = R.choice(AFINES[ui]) if AFINES[ui] and R.random() < 0.75 else R.randint(1, 250)
    if (ui, vi) in pares: continue
    u, v = U[ui], VAC[vi]
    ini = max(u["alta"], v["pub"], dt.date(2026, 7, 15)); fin = v["vista"] if v["cerrada"] else HOY
    if ini > fin: continue
    fe = dia(ini, min(fin, ini + dt.timedelta(days=21)))
    ds, g, gp = puntuar(ui, vi)
    ex, hu = textos(ui, vi, ds, g)
    pares.add((ui, vi)); EV.append(dict(u=ui, v=vi, ev=evaluador_ia(fe), f=fe, ds=ds, g=g, gp=gp, b=banda(g), ex=ex, hu=hu))
# comparaciones humanas (200) sobre pares ya evaluados por la IA
for e in R.sample(EV[:], 200):
    fe = dia(e["f"], min(HOY, e["f"] + dt.timedelta(days=5)))
    ds = [max(1, min(5, x + R.choice([-1, 0, 0, 0, 1]))) for x in e["ds"]]
    g = max(1.0, min(5.0, round(e["g"] + R.gauss(0, 0.35), 1)))
    ex = "Revisión manual. " + e["ex"].split(". ")[0] + "."
    EV.append(dict(u=e["u"], v=e["v"], ev=R.choice([3, 4]), f=fe, ds=ds, g=g, gp=g, b=banda(g), ex=ex, hu=e["hu"]))
EV.sort(key=lambda e: e["f"])
for n, e in enumerate(EV, 1):
    e["id"] = n
    OUT["EVALUACIONES"].append([n, e["u"], e["v"], e["ev"], f(e["f"])] + e["ds"] + [dec(e["g"]), dec(e["gp"]), e["b"], e["ex"], e["hu"], U[e["u"]]["hcv"]])

# ---------- CERTIFICADOS (40): la evaluación de IA más reciente del par, global >= 3,5
ult = {}
for e in EV:
    if e["ev"] in (1, 2, 5): ult[(e["u"], e["v"])] = e
cand = [e for e in ult.values() if e["g"] >= 3.5 and (HOY - e["f"]).days <= 60]
cand.sort(key=lambda e: -e["g"])
elegidos = []; usados_u = {}
for e in R.sample(cand, len(cand)):
    if usados_u.get(e["u"], 0) >= 2: continue
    elegidos.append(e); usados_u[e["u"]] = usados_u.get(e["u"], 0) + 1
    if len(elegidos) == 40: break
elegidos.sort(key=lambda e: e["f"])
CERT_PARES = set()
for n, e in enumerate(elegidos, 1):
    emi = dia(e["f"], min(HOY, e["f"] + dt.timedelta(days=6)))
    cad = emi + dt.timedelta(days=30)
    est = "revocado" if U[e["u"]]["est"] == "revocado" else ("vigente" if cad >= HOY else "caducado")
    cod = str(uuid.UUID(int=R.getrandbits(128), version=4))
    msg = "%s|%d|%d|%s|%s" % (cod, e["u"], e["v"], dec(e["g"]), f(emi))
    firma = hmac.new(SECRETO_DEMO, msg.encode(), hashlib.sha256).hexdigest()
    OUT["CERTIFICADOS"].append([n, e["u"], e["v"], e["id"], cod, firma, f(emi), f(cad), est, 0 if est == "revocado" else R.randint(0, 9)])
    CERT_PARES.add((e["u"], e["v"]))

# ---------- FEEDBACK (600) sobre pares evaluados
FB = []; vistos = set()
ia_pares = list(ult.values())
orden = R.sample(ia_pares, len(ia_pares)); orden.sort(key=lambda e: (e["u"], e["v"]) not in CERT_PARES)
for e in orden:
    if len(FB) >= 600: break
    k = (e["u"], e["v"])
    if k in vistos: continue
    vistos.add(k)
    fe = dia(e["f"], min(HOY, e["f"] + dt.timedelta(days=10)))
    if k in CERT_PARES: ver = R.choices(["postulada", "entrevista", "oferta", "descartada_por_empresa"], [35, 40, 10, 15])[0]
    elif e["g"] >= 4: ver = R.choices(["guardada", "postulada", "entrevista", "descartada", "descartada_por_empresa"], [30, 35, 15, 10, 10])[0]
    elif e["g"] >= 3: ver = R.choices(["guardada", "postulada", "descartada", "descartada_por_empresa"], [40, 20, 35, 5])[0]
    else: ver = R.choices(["descartada", "guardada"], [80, 20])[0]
    mot = ""
    if ver == "descartada":
        ds = e["ds"]
        mot = "salario" if ds[3] <= 2 and R.random() < 0.6 else R.choice(["sector", "lejos", "tarea", "empresa", "otro"])
    FB.append([e["u"], e["v"], ver, mot, f(fe)])
for k in CERT_PARES:
    if k not in vistos: pass
FB.sort(key=lambda r: d(r[4]))
for n, r in enumerate(FB, 1): OUT["FEEDBACK"].append([n] + r)

# ---------- escritura
os.makedirs("lanops_csv", exist_ok=True)
for t, desc, cols, *_ in T:
    with open("lanops_csv/%s.csv" % t, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, delimiter=";", quoting=csv.QUOTE_MINIMAL, lineterminator="\r\n")
        w.writerow(COLS[t]); w.writerows(OUT[t])
with open("lanops_csv/schema.ini", "w", encoding="cp1252", newline="\r\n") as fh:
    for t, desc, cols, *_ in T:
        fh.write("[%s.csv]\nColNameHeader=True\nFormat=Delimited(;)\nCharacterSet=65001\nTextDelimiter=\"\nDateTimeFormat=dd/mm/yyyy\nDecimalSymbol=,\nMaxScanRows=0\n" % t)
        for k, c in enumerate(cols, 1): fh.write("Col%d=%s %s\n" % (k, c["col"], c["ini"]))
        fh.write("\n")
for t in OUT: print(t, len(OUT[t]))
