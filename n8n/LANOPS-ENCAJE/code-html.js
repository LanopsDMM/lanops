// n8n · workflow LANOPS-ENCAJE · nodo "Code: HTML"
// Modo: Run Once for All Items · JavaScript · Settings del nodo previo "Postgres: lista": Always Output Data ON
// Página accesible (decisión 21): HTML semántico, lang, contraste, sin depender del color.
const filas = $input.all().map(i => i.json).filter(r => r.vacante);
// [07-oct] Botón "Pedir certificado" (decisión 99): reutiliza el enlace firmado del usuario. Solo banda Alta o Media (decisión 100).
const q = $('Webhook /encaje').first().json.query || {};
const pedir = (r) => (r.banda === 'Alta' || r.banda === 'Media')
  ? `<p><a class="boton" href="certificar?u=${encodeURIComponent(q.u)}&amp;t=${encodeURIComponent(q.t)}&amp;v=${r.vacante}">Pedir certificado de esta vacante</a></p>`
  : `<p class="meta">Certificado disponible solo con encaje alto o medio.</p>`;
// [07-oct] Lanbide no publica la empresa (decisión 96).
const empresa = (r) => r.fuente === 'lanbide' ? 'Empresa no publicada · oferta gestionada por Lanbide' : r.empresa;
// [08-oct] Botón "No me interesa" (LANOPS-FEEDBACK, opción B + IA): formulario GET a descartar?u=&t=&a=descartar&v=[&m=][&x=]
// Motivo con "solo quitarla" por defecto (no se aprende nada; mejor aprender menos que aprender mal).
// "x" = el porqué en palabras del usuario (≤ 200): el cuadro aparece al elegir cualquier motivo (se oculta con "solo quitarla";
// CSS :has, sin JavaScript; en navegadores sin :has se ve siempre) y es OBLIGATORIO con "otro motivo" (script mínimo).
// FEEDBACK tampoco acepta "otro" sin texto. Lo lee la IA y no va a ninguna tabla (FEEDBACK no guarda sus ejecuciones correctas).
const MOTIVOS = [['tarea', 'lo que se hace en el puesto'], ['sector', 'el sector'], ['empresa', 'la empresa'],
                 ['salario', 'el salario'], ['lejos', 'está lejos'], ['otro', 'otro motivo']];
const descartar = (r) => `<details class="descartar"><summary>No me interesa</summary>
  <form method="get" action="descartar">
  <input type="hidden" name="u" value="${esc(q.u)}"><input type="hidden" name="t" value="${esc(q.t)}">
  <input type="hidden" name="a" value="descartar"><input type="hidden" name="v" value="${r.vacante}">
  <p><label for="m-${r.vacante}">Motivo:</label>
  <select id="m-${r.vacante}" name="m"><option value="">solo quitarla</option>${MOTIVOS.map(([v, t]) => `<option value="${v}">${t}</option>`).join('')}</select></p>
  <p class="porque"><label for="x-${r.vacante}">Cuéntanos por qué (la IA lo lee para aprender; no se guarda en tu perfil):</label><br>
  <input type="text" id="x-${r.vacante}" name="x" maxlength="200" size="40"></p>
  <p><button type="submit">Descartar</button></p></form></details>`;
// [08-oct] Lista vacía: decir POR QUÉ (antes ponía "Vuelve en unos minutos", y no hay nada evaluando en segundo plano).
// Si el prefiltro no dejó pasar ninguna oferta → no hay ofertas que cumplan; si dejó pasar alguna → la evaluación falló ahora.
const candidatas = $('Postgres: prefiltro').all().filter(i => i.json.vacante).length;
const vacia = candidatas === 0
  ? 'Ahora mismo ninguna oferta abierta cumple tus no negociables y tus exclusiones. Cada mañana entran ofertas nuevas de Lanbide; también puedes revisar lo que LANOPS ha aprendido de ti.'
  : 'No hemos podido evaluar tus ofertas en este momento. Recarga la página dentro de un rato.';
const aprendido = `<p><a href="descartar?u=${encodeURIComponent(q.u)}&amp;t=${encodeURIComponent(q.t)}&amp;a=ver">Lo que LANOPS ha aprendido de ti</a></p>`;
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const nota = (g) => Number(g).toFixed(1).replace('.', ',');
const pct = (g) => Math.round(Number(g) * 20);           // decisión 26: % = global × 20
const DIM = [['d1_match_cv', 'Encaje con tu CV'], ['d2_north_star', 'Lo que buscas'],
             ['d3_compensacion', 'Salario'], ['d4_cultura', 'Empresa y condiciones'], ['d5_red_flags', 'Alertas (5 = ninguna)']];

const tarjeta = (r, n) => `
<li class="vac">
  <h2><span class="n">${n}.</span> ${esc(r.puesto)}</h2>
  <p class="meta">${esc(empresa(r))} · ${esc(r.ubicacion || 'ubicación no consta')}</p>
  <p class="nota"><strong>${pct(r.global)} % · ${nota(r.global)}/5</strong> — encaje ${({ Alta: 'alto', Media: 'medio', Baja: 'bajo' })[r.banda] || esc(r.banda)}</p>
  <ul class="dims">${DIM.map(([k, t]) => `<li>${t}: <strong>${r[k]}/5</strong></li>`).join('')}</ul>
  <p>${esc(r.explicacion).replace(/\n/g, '<br>')}</p>
  ${r.hueco ? `<p><strong>Para subir un punto:</strong> ${esc(r.hueco)}</p>` : ''}
  ${r.url_origen ? `<p><a href="${esc(r.url_origen)}" rel="noopener">Ver la oferta original${r.fuente === 'lanbide' ? ' en Lanbide' : ''}</a></p>` : ''}
  ${pedir(r)}
  ${descartar(r)}
</li>`;

const html = `<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Tus vacantes · LANOPS</title>
<style>
 body{font-family:system-ui,-apple-system,"Segoe UI",sans-serif;max-width:46rem;margin:0 auto;padding:1rem;line-height:1.5;color:#1a1a1a;background:#fff}
 h1{font-size:1.6rem} h2{font-size:1.15rem;margin:.2rem 0} .n{color:#555}
 ol{list-style:none;padding:0} .vac{border:1px solid #888;border-radius:.5rem;padding:1rem;margin:0 0 1rem}
 .meta{color:#444;margin:0} .nota{font-size:1.1rem} .dims{padding-left:1.2rem;margin:.3rem 0}
 a{color:#0b4fa8} a:focus{outline:3px solid #0b4fa8;outline-offset:2px}
 .descartar{margin:.5rem 0 0} .descartar summary{cursor:pointer;color:#0b4fa8} .descartar p{margin:.4rem 0}
 .descartar select,.descartar input,.descartar button{font:inherit} .descartar input{max-width:100%}
 .descartar:has(option[value=""]:checked) .porque{display:none}
 summary:focus,input:focus{outline:3px solid #0b4fa8;outline-offset:2px}
 .descartar button{padding:.25rem .7rem;border:2px solid #0b4fa8;border-radius:.4rem;background:#fff;color:#0b4fa8;cursor:pointer}
 button:focus,select:focus{outline:3px solid #0b4fa8;outline-offset:2px}
 .boton{display:inline-block;padding:.4rem .9rem;border:2px solid #0b4fa8;border-radius:.4rem;background:#0b4fa8;color:#fff;text-decoration:none}
 footer{font-size:.85rem;color:#444;border-top:1px solid #ccc;margin-top:2rem;padding-top:.5rem}
</style></head><body>
<header><h1>Tus vacantes con más encaje</h1>
<p>${filas.length ? `${filas.length} vacantes abiertas, ordenadas por lo que tú priorizas.` : vacia}</p>${aprendido}</header>
<main><ol>${filas.map((r, i) => tarjeta(r, i + 1)).join('')}</ol></main>
<footer><p>La IA evalúa; tú decides. Puntuación con la rúbrica abierta de career-ops (MIT). Ofertas de Lanbide: Fuente Lanbide / Open Data Euskadi (CC BY).</p></footer>
<script>
// "Cuéntanos por qué" es obligatorio solo con "otro motivo" (si no hay JavaScript, FEEDBACK lo comprueba igualmente)
document.querySelectorAll('details.descartar select').forEach(function (s) {
  var x = document.getElementById('x-' + s.id.slice(2));
  var f = function () { x.required = s.value === 'otro'; };
  s.addEventListener('change', f); f();
});
</script>
</body></html>`;
return [{ json: { html } }];
