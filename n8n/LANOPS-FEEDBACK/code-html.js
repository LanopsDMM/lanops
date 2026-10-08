// n8n · workflow LANOPS-FEEDBACK · nodo "Code: HTML"  (detrás de "Postgres: aprendido")
// Modo: Run Once for All Items · JavaScript
// Página "Lo que LANOPS ha aprendido de ti": mensaje de la acción + lo aprendido (deshacer) + descartes (recuperar)
// + perfil de búsqueda (solo consulta). Usa $('Code: entrada'), $('Postgres: aplicar') y $('Postgres: aprender'):
// **los nombres de esos nodos deben ser exactos**. Accesible (decisión 21): HTML semántico, formularios con
// etiqueta, mensaje en role="status", nada depende solo del color. Sin JavaScript en la página.
const CORREGIR_PERFIL = 'Si algún dato no es correcto, dínoslo y lo corregimos.';   // [08-oct] texto provisional

const e = $('Code: entrada').first().json;
const a = $('Postgres: aplicar').first().json || {};
const ap = $('Postgres: aprender').first().json || {};
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
const motivo = (m) => (m ? MOTIVO[m] || m : 'sin motivo');
const QUE = (c, v) => (c === 'empresa' ? `la empresa <strong>${esc(v)}</strong>` : `el sector <strong>${esc(v)}</strong>`);
const DE = (c, v) => (c === 'empresa' ? `de la empresa <strong>${esc(v)}</strong>` : `del sector <strong>${esc(v)}</strong>`);
const CLAVE = { municipio: 'Municipio', radio_km: 'Distancia máxima (km)', jornada: 'Jornada', contrato: 'Contrato',
  salario_min: 'Salario mínimo', modalidad: 'Modalidad', fecha_inicio_max: 'Incorporación antes de', permiso_trabajo: 'Permiso de trabajo',
  euskera: 'Euskera', sector: 'Sector', tamano: 'Tamaño de empresa', idioma: 'Idioma', estabilidad: 'Estabilidad', ett: 'ETT',
  palabra: 'Palabra', empresa: 'Empresa', movilidad: 'Movilidad', turnos: 'Turnos', puesto_objetivo: 'Puesto que buscas',
  situacion_actual: 'Situación actual' };
const TIPO = (p) => (p.tipo === 'duro' ? 'No negociable' : p.tipo === 'peso' ? `Importante (${p.peso}/5)` : 'Excluyes');
const oculto = (r) => [...aprendidas, ...perfil.filter(p => p.tipo === 'exclusion')].some(x =>
  (x.clave === 'empresa' && r.empresa_tocada && norm(x.valor) === norm(r.empresa_tocada)) ||
  (x.clave === 'sector' && r.sector_tocado && norm(r.sector_tocado).includes(norm(x.valor))));

// Formularios: GET al mismo webhook (relativo: vale en la Test URL y en la Production URL)
const ocultos = `<input type="hidden" name="u" value="${esc(e.usuario)}"><input type="hidden" name="t" value="${esc(e.t)}">`;
const formRecuperar = (r) => `<form method="get" action="descartar">${ocultos}
  <input type="hidden" name="a" value="recuperar"><input type="hidden" name="v" value="${esc(r.vacante)}">
  <button type="submit">Recuperar esta oferta</button></form>`;
const formOlvidar = (x) => `<form method="get" action="descartar">${ocultos}
  <input type="hidden" name="a" value="olvidar"><input type="hidden" name="k" value="${esc(x.clave)}">
  <input type="hidden" name="val" value="${esc(x.valor)}">
  <button type="submit">Dejar de excluir ${x.clave === 'empresa' ? 'esta empresa' : 'este sector'}</button></form>`;

// 1. Qué ha pasado
const msg = [];
if (e.accion === 'descartar') {
  if (!a.hecho) msg.push('Esa oferta no existe.');
  else {
    msg.push(`Has descartado «${esc(a.puesto)}» (${esc(a.empresa)}) por ${esc(motivo(a.motivo))}. No volverá a salir en tu lista.`);
    for (const x of nuevas) msg.push(x.clave === 'empresa'
      ? `<strong>Hemos aprendido:</strong> desde ahora no te enseñaremos ofertas ${DE('empresa', x.valor)}.`
      : `<strong>Hemos aprendido:</strong> llevas ${umbral} o más ofertas descartadas por el sector ${esc(x.valor)}; desde ahora no te enseñaremos ofertas de ese sector.`);
    if (a.motivo === 'empresa' && a.fuente === 'lanbide')
      msg.push('Lanbide no publica el nombre de la empresa, así que no podemos dejar de enseñártela. Tu motivo queda guardado.');
    if (a.motivo === 'sector' && !a.sector_tocado)
      msg.push('No sabemos el sector de esta empresa, así que no podemos aprender de este descarte. Tu motivo queda guardado.');
    const c = enCamino.find(s => a.sector_tocado && norm(s.valor) === norm(a.sector_tocado));
    if (a.motivo === 'sector' && c)
      msg.push(`Si descartas ${c.faltan === 1 ? 'una oferta más' : c.faltan + ' ofertas más'} del sector ${esc(c.valor)} por el sector, dejaremos de enseñarte ese sector.`);
  }
} else if (e.accion === 'recuperar') {
  if (!a.hecho) msg.push('Esa oferta no estaba entre tus descartes.');
  else {
    for (const x of retiradas) msg.push(`Ya no excluimos ${QUE(x.clave, x.valor)}: no quedan descartes que lo justifiquen.`);
    msg.unshift(oculto(a)
      ? `«${esc(a.puesto)}» ya no está entre tus descartes, pero no la verás en tu lista mientras excluyas su empresa o su sector (más abajo puedes dejar de excluirlos).`
      : `«${esc(a.puesto)}» vuelve a tu lista.`);
  }
} else if (e.accion === 'olvidar') {
  msg.push(a.hecho
    ? `Ya no excluimos ${QUE(a.clave, a.valor)}. Las ofertas que descartaste por eso siguen descartadas; si quieres verlas, recupéralas abajo.`
    : 'No había nada aprendido con ese nombre.');
}

// 2. Secciones
const liAprendida = (x) => `<li>No te enseñamos ofertas ${DE(x.clave, x.valor)}.
  <span class="meta">Lo aprendimos de ${x.descartes === 1 ? '1 descarte' : x.descartes + ' descartes'} · desde el ${fecha(x.desde)}.</span>
  ${formOlvidar(x)}</li>`;
const liCamino = (s) => `<li>Sector ${esc(s.valor)}: ${s.descartes} de ${umbral} descartes por el sector.</li>`;
const liDescarte = (r) => `<li class="vac"><h3>${esc(r.puesto)}</h3>
  <p class="meta">${esc(r.empresa)}${r.sector ? ' · sector ' + esc(r.sector) : ''} · descartada el ${fecha(r.fecha)} ${r.motivo ? 'por ' + esc(motivo(r.motivo)) : 'sin motivo'}</p>
  ${r.oculta ? '<p class="meta">Aunque la recuperes, no la verás mientras excluyas su empresa o su sector.</p>' : ''}
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
 .aviso{border-left:4px solid #0b4fa8;background:#eef4fc;padding:.6rem 1rem;margin:1rem 0}
 a{color:#0b4fa8} a:focus,button:focus{outline:3px solid #0b4fa8;outline-offset:2px}
 button{font:inherit;padding:.3rem .8rem;border:2px solid #0b4fa8;border-radius:.4rem;background:#fff;color:#0b4fa8;cursor:pointer}
 footer{font-size:.85rem;color:#444;border-top:1px solid #ccc;margin-top:2rem;padding-top:.5rem}
</style></head><body>
<header><h1>Lo que LANOPS ha aprendido de ti</h1>${volver}</header>
<main>
${msg.length ? `<div class="aviso" role="status">${msg.map(m => `<p>${m}</p>`).join('')}</div>` : ''}
<p>LANOPS aprende de tus descartes con dos reglas, y aquí puedes deshacer lo que aprende:
si descartas una oferta por <em>la empresa</em>, dejamos de enseñarte esa empresa; si descartas ${umbral} ofertas
del mismo sector por <em>el sector</em>, dejamos de enseñarte ese sector. El resto de motivos se guardan, pero no cambian tu lista.</p>

<h2>Lo que hemos aprendido</h2>
${aprendidas.length ? `<ul>${aprendidas.map(liAprendida).join('')}</ul>` : '<p>Todavía nada.</p>'}
${enCamino.length ? `<h2>A punto de aprender</h2><ul>${enCamino.map(liCamino).join('')}</ul>` : ''}

<h2>Ofertas que has descartado</h2>
${descartes.length ? `<ul class="vacs">${descartes.map(liDescarte).join('')}</ul>` : '<p>No has descartado ninguna oferta.</p>'}

<h2>Tu perfil de búsqueda</h2>
<p>Lo que nos dijiste al darte de alta. ${esc(CORREGIR_PERFIL)}</p>
${perfil.length ? `<ul>${perfil.map(liPerfil).join('')}</ul>` : '<p>No has indicado preferencias.</p>'}
</main>
<footer><p>La IA evalúa cada oferta; tú decides. Lo que aprende LANOPS de tus descartes son reglas a la vista que puedes deshacer.</p></footer>
</body></html>`;
return [{ json: { html, status: 200 } }];
