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
 .boton{display:inline-block;padding:.4rem .9rem;border:2px solid #0b4fa8;border-radius:.4rem;background:#0b4fa8;color:#fff;text-decoration:none}
 footer{font-size:.85rem;color:#444;border-top:1px solid #ccc;margin-top:2rem;padding-top:.5rem}
</style></head><body>
<header><h1>Tus vacantes con más encaje</h1>
<p>${filas.length ? `${filas.length} vacantes abiertas, ordenadas por lo que tú priorizas.` : 'Todavía no hay vacantes evaluadas para ti. Vuelve en unos minutos.'}</p></header>
<main><ol>${filas.map((r, i) => tarjeta(r, i + 1)).join('')}</ol></main>
<footer><p>La IA evalúa; tú decides. Puntuación con la rúbrica abierta de career-ops (MIT). Ofertas de Lanbide: Fuente Lanbide / Open Data Euskadi (CC BY).</p></footer>
</body></html>`;
return [{ json: { html } }];
