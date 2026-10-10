// n8n · workflow LANOPS-AGENTE · nodo "Code: texto y petición"
// Modo: Run Once for All Items · JavaScript
// Entrada: respuestas de "HTTP Request: página de empleo", en el mismo orden que "Code: robots.txt".
// HTML → texto (≤ 15.000 caracteres). Si la página trae JSON-LD JobPosting, se le pasa a Claude ese JSON (más fiable).
// Salida: SOLO las empresas con página leída, con la petición a Claude. Las fallidas se cuentan en "Code: leer".
const empresas = $('Code: robots.txt').all().map(i => i.json);
const MODELO = 'claude-sonnet-5-5';
const ENT = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', aacute: 'á', eacute: 'é', iacute: 'í', oacute: 'ó',
  uacute: 'ú', ntilde: 'ñ', Aacute: 'Á', Eacute: 'É', Iacute: 'Í', Oacute: 'Ó', Uacute: 'Ú', Ntilde: 'Ñ', uuml: 'ü', ordf: 'ª', ordm: 'º', euro: '€' };
const decod = (s) => s.replace(/&(#x?[0-9a-f]+|\w+);/gi, (m, c) => c[0] === '#'
  ? String.fromCodePoint(parseInt(c[1].toLowerCase() === 'x' ? c.slice(2) : c.slice(1), c[1].toLowerCase() === 'x' ? 16 : 10))
  : (ENT[c] ?? m));
function jsonLd(html) {
  const out = [];
  for (const m of html.matchAll(/<script[^>]*application\/ld\+json[^>]*>([\s\S]*?)<\/script>/gi)) {
    try {
      const walk = (o) => { if (!o || typeof o !== 'object') return;
        if (Array.isArray(o)) return o.forEach(walk);
        const t = [].concat(o['@type'] || []); if (t.includes('JobPosting')) out.push(o);
        if (o['@graph']) walk(o['@graph']); if (o.itemListElement) walk(o.itemListElement); if (o.item) walk(o.item); };
      walk(JSON.parse(m[1].trim()));
    } catch (e) {}
  }
  return out;
}
function texto(html) {
  return decod(html
    .replace(/<(script|style|noscript|svg|head)[\s\S]*?<\/\1>/gi, ' ')
    .replace(/<a\s[^>]*href="([^"#][^"]*)"[^>]*>/gi, ' [enlace: $1] ')
    .replace(/<(br|p|div|li|h[1-6]|tr|section|article)[^>]*>/gi, '\n')
    .replace(/<[^>]+>/g, ' '))
    .replace(/[ \t]+/g, ' ').replace(/\n\s*\n+/g, '\n').trim();
}
const SYSTEM = `Eres el agente de webs de LANOPS (red de empleo de Gipuzkoa). Recibes la página de empleo de UNA empresa
(texto de la página, con los enlaces marcados como [enlace: …], o datos JSON-LD JobPosting).
Devuelve SOLO un JSON: {"vacantes":[{"puesto":"","ubicacion":"","contrato":"indefinido|temporal|practicas|otro|","jornada":"completa|parcial|","salario_min":0,"descripcion":"","url":""}],"candidatura_espontanea":false,"como_enviar":""}
Reglas:
- Solo ofertas de empleo concretas que la página publica AHORA. No inventes nada; un campo que no está va vacío ("" o 0).
- Ignora menús, noticias, cookies, ofertas cerradas o caducadas y procesos de "bolsa" sin puesto concreto.
- url: el enlace a la ficha de esa oferta si aparece (completo; si es relativo, tal cual); si no, "".
- descripcion: lo que la página diga del puesto (funciones, requisitos), máximo 1500 caracteres.
- Máximo 30 ofertas.
- Si NO hay ninguna oferta concreta pero la página invita a enviar el CV (formulario, correo de RR. HH., "trabaja con nosotros"),
  candidatura_espontanea = true y como_enviar = cómo se envía (correo o formulario), en una frase.`;

const salida = [];
$input.all().forEach((item, i) => {
  const e = empresas[i]; if (!e) return;
  const j = item.json, status = Number(j.statusCode || 0);
  const html = String(j.body ?? j.data ?? '');
  if (j.error || status < 200 || status >= 400 || html.length < 200) return;   // fallo de lectura
  const ld = jsonLd(html);
  const contenido = ld.length
    ? 'JSON-LD JobPosting de la página:\n' + JSON.stringify(ld).slice(0, 15000)
    : 'Texto de la página:\n' + texto(html).slice(0, 15000);
  salida.push({ json: { ...e, fuente_lectura: ld.length ? 'jsonld' : 'html', cuerpo: {
    model: MODELO, max_tokens: 8000, system: SYSTEM,
    messages: [{ role: 'user', content: `Empresa: ${e.nombre} (${e.ciudad || 'Gipuzkoa'})\nURL: ${e.url_empleo}\n\n${contenido}` }]
  } } });
});
return salida;
