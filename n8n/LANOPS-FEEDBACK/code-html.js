// n8n · workflow LANOPS-FEEDBACK · nodo "Code: HTML"  (detrás de "Postgres: aprendido")
// Modo: Run Once for All Items · JavaScript
// Página "Lo que LANOPS ha aprendido de ti": mensaje de la acción + reglas aprendidas (quitar) + descartes (recuperar)
// + perfil de búsqueda del alta (solo consulta: se cambia en el alta, Pieza 6).
// Usa $('Code: entrada'), $('Postgres: aplicar'), $('Postgres: aprender') y, si corrió, $('Code: leer regla'):
// **los nombres de esos nodos deben ser exactos**. Accesible (decisión 21): HTML semántico, formularios con
// etiqueta, mensaje en role="status", nada depende solo del color. Sin JavaScript en la página.
const CAMBIAR_PERFIL = 'Para cambiar algo de aquí, hazlo desde tu alta en LANOPS.';   // [08-oct] depende del alta (Pieza 6)

const e = $('Code: entrada').first().json;
const a = $('Postgres: aplicar').first().json || {};
const ap = $('Postgres: aprender').first().json || {};
let ia = null;
try { ia = $('Code: leer regla').first().json; } catch (_) { ia = null; }   // no corrió: no se preguntó a la IA
const st = $input.first().json || {};
const json = (x) => (typeof x === 'string' ? JSON.parse(x) : (x || []));
const aprendidas = json(st.aprendidas), enCamino = json(st.en_camino), descartes = json(st.descartes), perfil = json(st.perfil);
const nuevas = json(ap.aprendidas), retiradas = json(ap.retiradas);
const umbral = Number(st.umbral) || 2;

const esc = (s) => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const norm = (s) => String(s ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();
const fecha = (f) => (f ? f.split('-').reverse().join('/') : '');
const MOTIVO = { tarea: 'lo que se hace en el puesto', sector: 'el sector', empresa: 'la empresa',
                 salario: 'el salario', lejos: 'está lejos', otro: 'otro motivo' };
const CONTRATO = { temporal: 'temporal', practicas: 'de prácticas', otro: 'de otro tipo', indefinido: 'indefinido' };
const ES_IA = (c) => ['palabra', 'municipio', 'contrato'].includes(c);
// "ofertas …" según el tipo de regla
const OFERTAS = (c, v) => ({
  empresa: `ofertas de la empresa <strong>${esc(v)}</strong>`,
  sector: `ofertas del sector <strong>${esc(v)}</strong>`,
  palabra: `ofertas que mencionan <strong>«${esc(v)}»</strong>`,
  municipio: `ofertas en <strong>${esc(v)}</strong>`,
  contrato: `ofertas con contrato <strong>${esc(CONTRATO[v] || v)}</strong>`,
}[c] || `ofertas con ${esc(c)} = ${esc(v)}`);
const CLAVE = { municipio: 'Municipio', radio_km: 'Distancia máxima (km)', jornada: 'Jornada', contrato: 'Contrato',
  salario_min: 'Salario mínimo', modalidad: 'Modalidad', fecha_inicio_max: 'Incorporación antes de', permiso_trabajo: 'Permiso de trabajo',
  euskera: 'Euskera', sector: 'Sector', tamano: 'Tamaño de empresa', idioma: 'Idioma', estabilidad: 'Estabilidad', ett: 'ETT',
  palabra: 'Palabra', empresa: 'Empresa', movilidad: 'Movilidad', turnos: 'Turnos', puesto_objetivo: 'Puesto que buscas',
  situacion_actual: 'Situación actual' };
const TIPO = (p) => (p.tipo === 'duro' ? 'No negociable' : p.tipo === 'peso' ? `Importante (${p.peso}/5)` : 'Excluyes');

// Formularios: GET al mismo webhook (relativo: vale en la Test URL y en la Production URL)
const ocultos = `<input type="hidden" name="u" value="${esc(e.usuario)}"><input type="hidden" name="t" value="${esc(e.t)}">`;
const formRecuperar = (r) => `<form method="get" action="descartar">${ocultos}
  <input type="hidden" name="a" value="recuperar"><input type="hidden" name="v" value="${esc(r.vacante)}">
  <button type="submit">Recuperar esta oferta</button></form>`;
const formQuitar = (x) => `<form method="get" action="descartar">${ocultos}
  <input type="hidden" name="a" value="olvidar"><input type="hidden" name="k" value="${esc(x.clave)}">
  <input type="hidden" name="val" value="${esc(x.valor)}">
  <button type="submit">Quitar esta regla</button></form>`;

// 1. Qué ha pasado
const msg = [];
if (e.accion === 'descartar') {
  if (!a.hecho) msg.push('Esa oferta no existe.');
  else {
    msg.push(a.motivo
      ? `Has descartado «${esc(a.puesto)}» (${esc(a.empresa)}) por ${esc(MOTIVO[a.motivo])}. No volverá a salir en tu lista.`
      : `Has quitado «${esc(a.puesto)}» (${esc(a.empresa)}) de tu lista. Sin motivo, no aprendemos nada de este descarte.`);
    for (const x of nuevas) {
      if (x.ia) msg.push(`<strong>La IA ha aprendido:</strong> desde ahora no te enseñaremos ${OFERTAS(x.clave, x.valor)}.`
        + (ia && ia.porque ? ` <em>${esc(ia.porque)}</em>` : ''));
      else if (x.clave === 'empresa') msg.push(`<strong>Hemos aprendido:</strong> desde ahora no te enseñaremos ${OFERTAS('empresa', x.valor)}.`);
      else msg.push(`<strong>Hemos aprendido:</strong> llevas ${umbral} o más ofertas descartadas por el sector ${esc(x.valor)}; desde ahora no te enseñaremos ${OFERTAS('sector', x.valor)}.`);
    }
    if (ia && !ia.regla && ia.porque && !nuevas.some(x => x.ia))
      msg.push(`La IA ha leído la oferta y no ve una regla clara que aprender: <em>${esc(ia.porque)}</em>`);
    if (a.nuevo && a.motivo === 'empresa' && a.fuente === 'lanbide')
      msg.push('Lanbide no publica el nombre de la empresa, así que no podemos dejar de enseñártela.');
    const c = enCamino.find(s => a.sector_tocado && norm(s.valor) === norm(a.sector_tocado));
    if (a.motivo === 'sector' && c)
      msg.push(`Si descartas ${c.faltan === 1 ? 'una oferta más' : c.faltan + ' ofertas más'} del sector ${esc(c.valor)} por el sector, dejaremos de enseñarte ese sector.`);
  }
} else if (e.accion === 'falta_porque') {
  msg.push(`No hemos descartado «${esc(a.puesto || 'la oferta')}»: si eliges «otro motivo», cuéntanos por qué. Vuelve a tu lista y escríbelo, o elige «solo quitarla».`);
} else if (e.accion === 'recuperar') {
  if (!a.hecho) msg.push('Esa oferta no estaba entre tus descartes.');
  else {
    msg.push(st.tocada_oculta
      ? `«${esc(a.puesto)}» ya no está entre tus descartes, pero no la verás en tu lista mientras tengas una regla que la esconda (más abajo puedes quitarla).`
      : `«${esc(a.puesto)}» vuelve a tu lista.`);
    for (const x of retiradas) msg.push(`Hemos quitado la regla que escondía ${OFERTAS(x.clave, x.valor)}: no quedan descartes que la justifiquen.`);
  }
} else if (e.accion === 'olvidar') {
  msg.push(a.hecho
    ? `Hemos quitado la regla: vuelves a ver ${OFERTAS(a.clave, a.valor)}. Las ofertas que descartaste siguen descartadas; si quieres verlas, recupéralas abajo.`
    : 'No había ninguna regla aprendida con ese nombre.');
}

// 2. Secciones
const liAprendida = (x) => `<li>No te enseñamos ${OFERTAS(x.clave, x.valor)}${ES_IA(x.clave) ? ' <span class="etq">propuesta por la IA</span>' : ''}.
  <span class="meta">Aprendido de ${x.descartes === 1 ? '1 descarte' : x.descartes + ' descartes'} el ${fecha(x.desde)} ·
  ahora esconde ${x.ocultas === 1 ? '1 oferta abierta' : x.ocultas + ' ofertas abiertas'}.</span>
  ${formQuitar(x)}</li>`;
const liCamino = (s) => `<li>Sector ${esc(s.valor)}: ${s.descartes} de ${umbral} descartes por el sector.</li>`;
const liDescarte = (r) => `<li class="vac"><h3>${esc(r.puesto)}</h3>
  <p class="meta">${esc(r.empresa)}${r.sector ? ' · sector ' + esc(r.sector) : ''} · descartada el ${fecha(r.fecha)} ${r.motivo ? 'por ' + esc(MOTIVO[r.motivo] || r.motivo) : 'sin motivo'}</p>
  ${r.oculta ? '<p class="meta">Aunque la recuperes, no la verás mientras tengas una regla que la esconda.</p>' : ''}
  ${formRecuperar(r)}</li>`;
const liPerfil = (p) => `<li>${TIPO(p)} · ${esc(CLAVE[p.clave] || p.clave)}: <strong>${esc(String(p.valor).replace(/_/g, ' '))}</strong></li>`;
const volver = `<p><a href="encaje?u=${encodeURIComponent(e.usuario)}&amp;t=${encodeURIComponent(e.t)}">Volver a tu lista de vacantes</a></p>`;

const html = `<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Lo que LANOPS ha aprendido de ti</title>
<style>
 body{font-family:system-ui,-apple-system,"Segoe UI",sans-serif;max-width:46rem;margin:0 auto;padding:1rem;line-height:1.5;color:#1a1a1a;background:#fff}
 h1{font-size:1.6rem} h2{font-size:1.25rem;margin-top:2rem} h3{font-size:1.05rem;margin:.2rem 0}
 ul{padding-left:1.2rem} .vacs{list-style:none;padding:0} .vac{border:1px solid #888;border-radius:.5rem;padding:.8rem 1rem;margin:0 0 .8rem}
 .meta{color:#444;margin:.2rem 0} form{margin:.4rem 0 .8rem}
 .etq{font-size:.85rem;border:1px solid #555;border-radius:.3rem;padding:0 .3rem;color:#333}
 .aviso{border-left:4px solid #0b4fa8;background:#eef4fc;padding:.6rem 1rem;margin:1rem 0}
 a{color:#0b4fa8} a:focus,button:focus{outline:3px solid #0b4fa8;outline-offset:2px}
 button{font:inherit;padding:.3rem .8rem;border:2px solid #0b4fa8;border-radius:.4rem;background:#fff;color:#0b4fa8;cursor:pointer}
 footer{font-size:.85rem;color:#444;border-top:1px solid #ccc;margin-top:2rem;padding-top:.5rem}
</style></head><body>
<header><h1>Lo que LANOPS ha aprendido de ti</h1>${volver}</header>
<main>
${msg.length ? `<div class="aviso" role="status">${msg.map(m => `<p>${m}</p>`).join('')}</div>` : ''}
<p>Cuando descartas una oferta y nos dices por qué, LANOPS aprende para no enseñarte ofertas parecidas:
si es por <em>la empresa</em>, dejamos de enseñarte esa empresa; si descartas ${umbral} ofertas del mismo sector por
<em>el sector</em>, ese sector; con los demás motivos, la IA lee la oferta y puede proponer una regla (una palabra
del puesto, un municipio o un tipo de contrato). Todo lo aprendido está aquí y puedes quitarlo.</p>

<h2>Lo que hemos aprendido</h2>
${aprendidas.length ? `<ul>${aprendidas.map(liAprendida).join('')}</ul>` : '<p>Todavía nada.</p>'}
${enCamino.length ? `<h2>A punto de aprender</h2><ul>${enCamino.map(liCamino).join('')}</ul>` : ''}

<h2>Ofertas que has descartado</h2>
${descartes.length ? `<ul class="vacs">${descartes.map(liDescarte).join('')}</ul>` : '<p>No has descartado ninguna oferta.</p>'}

<h2>Tu perfil de búsqueda</h2>
<p>Lo que nos dijiste al darte de alta. ${esc(CAMBIAR_PERFIL)}</p>
${perfil.length ? `<ul>${perfil.map(liPerfil).join('')}</ul>` : '<p>No has indicado preferencias.</p>'}
</main>
<footer><p>La IA evalúa cada oferta con la rúbrica abierta de career-ops y propone reglas; tú decides y puedes quitarlas.</p></footer>
</body></html>`;
return [{ json: { html, status: 200 } }];
