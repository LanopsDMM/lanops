// n8n · workflow LANOPS-AGENTE · nodo "Code: leer"
// Modo: Run Once for All Items · JavaScript
// Entrada: respuestas de "HTTP Request: Claude", en el mismo orden que "Code: texto y petición".
// Salida: UN item con todas las vacantes leídas y el resultado de cada empresa, para "Postgres: guardar".
// ok = página leída y (≥ 1 oferta o candidatura espontánea). Bloqueada por robots.txt = no cuenta (ni ok ni fallo).
const todas = $('Postgres: empresas').all().map(i => i.json);
const permitidas = new Set($('Code: robots.txt').all().map(i => i.json.empresa));
const leidas = $('Code: texto y petición').all().map(i => i.json);
const txt = (v, n) => String(v ?? '').trim().slice(0, n);
const abs = (u, base) => {
  u = String(u || '').trim(); if (!u) return base;
  if (/^https?:\/\//i.test(u)) return u.slice(0, 255);
  const origen = (base.match(/^https?:\/\/[^/?#]+/) || [''])[0];
  return (u.startsWith('/') ? origen + u : base.replace(/[^/]*$/, '') + u).slice(0, 255);
};

const vacantes = [], lecturas = [], resumen = [];
const porEmpresa = new Map();
$input.all().forEach((item, i) => {
  const e = leidas[i]; if (!e) return;
  try {
    const t = (item.json.content || []).filter(b => b.type === 'text').map(b => b.text).join('');
    const r = JSON.parse(t.slice(t.indexOf('{'), t.lastIndexOf('}') + 1));
    porEmpresa.set(e.empresa, { e, r });
  } catch (err) { porEmpresa.set(e.empresa, { e, r: null }); }
});

for (const emp of todas) {
  if (!permitidas.has(emp.empresa)) { resumen.push(`${emp.nombre}: bloqueada por robots.txt (no se visita)`); continue; }
  const x = porEmpresa.get(emp.empresa);
  if (!x) { lecturas.push({ empresa: emp.empresa, ok: false }); resumen.push(`${emp.nombre}: no se pudo leer la página`); continue; }
  if (!x.r) { lecturas.push({ empresa: emp.empresa, ok: false }); resumen.push(`${emp.nombre}: respuesta de Claude no válida`); continue; }
  const lista = (Array.isArray(x.r.vacantes) ? x.r.vacantes : []).slice(0, 30)
    .map(v => ({
      empresa: emp.empresa,
      puesto: txt(v.puesto, 150),
      ubicacion: txt(v.ubicacion, 60) || null,
      contrato: ['indefinido', 'temporal', 'practicas', 'otro'].includes(v.contrato) ? v.contrato : null,
      jornada: ['completa', 'parcial'].includes(v.jornada) ? v.jornada : null,
      salario_min: parseInt(v.salario_min, 10) > 0 ? parseInt(v.salario_min, 10) : null,
      requisitos: txt(v.descripcion, 1500) || null,
      url_origen: abs(v.url, emp.url_empleo)
    }))
    .filter(v => v.puesto);
  if (!lista.length && x.r.candidatura_espontanea) {
    lista.push({ empresa: emp.empresa, puesto: 'Candidatura espontánea', ubicacion: emp.ciudad || null, contrato: null,
      jornada: null, salario_min: null, url_origen: emp.url_empleo,
      requisitos: txt(`${emp.nombre} no publica ofertas concretas pero recibe candidaturas. ${x.r.como_enviar || ''}`, 1500) });
  }
  vacantes.push(...lista);
  lecturas.push({ empresa: emp.empresa, ok: lista.length > 0 });
  resumen.push(`${emp.nombre} (${x.e.fuente_lectura}): ${lista.length ? lista.length + ' ofertas' : 'ninguna oferta en el texto (¿ATS con JavaScript?)'}`);
}
return [{ json: { datos: { vacantes, lecturas }, resumen } }];
