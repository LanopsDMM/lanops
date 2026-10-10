// n8n · workflow LANOPS-AGENTE · nodo "Code: robots.txt"
// Modo: Run Once for All Items · JavaScript
// Entrada: respuestas de "HTTP Request: robots.txt", en el mismo orden que "Postgres: empresas".
// Salida: SOLO las empresas cuya url_empleo permite robots.txt (las demás no se visitan).
// Reglas: 200 → se aplican los Disallow/Allow del grupo "LANOPS-bot" o, si no hay, del grupo "*" (gana la regla más larga);
// 4xx (no hay robots.txt) → permitido; 5xx o error de red → NO permitido (lo prudente).
const empresas = $('Postgres: empresas').all().map(i => i.json);
const UA = 'lanops-bot';

function reglas(texto) {
  const grupos = []; let actual = null, leyendoAgentes = false;
  for (const linea of String(texto).split(/\r?\n/)) {
    const l = linea.replace(/#.*/, '').trim(); if (!l) continue;
    const m = l.match(/^([A-Za-z-]+)\s*:\s*(.*)$/); if (!m) continue;
    const k = m[1].toLowerCase(), v = m[2].trim();
    if (k === 'user-agent') {
      if (!leyendoAgentes) { actual = { agentes: [], reglas: [] }; grupos.push(actual); }
      actual.agentes.push(v.toLowerCase()); leyendoAgentes = true;
    } else if (actual && (k === 'disallow' || k === 'allow')) {
      leyendoAgentes = false; if (v) actual.reglas.push({ permitir: k === 'allow', ruta: v });
    } else { leyendoAgentes = false; }
  }
  const propio = grupos.filter(g => g.agentes.some(a => a !== '*' && UA.startsWith(a)));
  const usar = propio.length ? propio : grupos.filter(g => g.agentes.includes('*'));
  return usar.flatMap(g => g.reglas);
}
const casa = (ruta, patron) => {
  const re = '^' + patron.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*').replace(/\\\$$/, '$');
  return new RegExp(re.endsWith('$') ? re : re).test(ruta);
};
function permitido(url, texto) {
  const ruta = (String(url).match(/^https?:\/\/[^/?#]+([^#]*)/) || [])[1] || '/';
  let mejor = null;
  for (const r of reglas(texto)) if (casa(ruta || '/', r.ruta) && (!mejor || r.ruta.length > mejor.ruta.length)) mejor = r;
  return !mejor || mejor.permitir;
}

const salida = [];
$input.all().forEach((item, i) => {
  const e = empresas[i]; if (!e) return;
  const j = item.json, status = Number(j.statusCode || 0);
  let ok;
  if (j.error || !status || status >= 500) ok = false;
  else if (status >= 400) ok = true;
  else ok = permitido(e.url_empleo, j.body ?? j.data ?? '');
  if (ok) salida.push({ json: e });
});
return salida;
