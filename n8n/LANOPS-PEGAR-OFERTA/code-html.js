// n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Code: HTML"
// Modo: Run Once for All Items · JavaScript
// Página con el resultado de la oferta pegada, con la misma tarjeta que LANOPS-ENCAJE/code-html.js
// (estilo común, % = global × 20, banda con texto, 5 dimensiones). "Pedir certificado" solo con banda Alta o Media.
const N8N = 'https://n8n-production-3c20b.up.railway.app/webhook';
const r = $input.first().json;                          // "Postgres: guardar evaluación"
const v = $('Postgres: guardar vacante').first().json;
const e = $('Code: entrada').first().json;
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const nota = (g) => Number(g).toFixed(1).replace('.', ',');
const pct = (g) => Math.round(Number(g) * 20);
const BANDA = { Alta: 'alto', Media: 'medio', Baja: 'bajo' };
const DIM = [['d1_match_cv', 'Encaje con tu CV'], ['d2_north_star', 'Lo que buscas'],
             ['d3_compensacion', 'Salario'], ['d4_cultura', 'Empresa y condiciones'], ['d5_red_flags', 'Alertas (5 = ninguna)']];
const firma = `u=${e.usuario}&amp;t=${e.t}`;
const pedir = (r.banda === 'Alta' || r.banda === 'Media')
  ? `<p><a class="boton" href="${N8N}/certificar?${firma}&amp;v=${r.vacante}">Pedir certificado de esta vacante</a></p>`
  : `<p class="meta">Certificado disponible solo con encaje alto o medio.</p>`;

const html = `<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex">
<title>Tu encaje con esta oferta · LANOPS</title>
<link rel="stylesheet" href="https://lanopsdmm.github.io/lanops/styles.css"></head><body>
<header><p class="marca">LANOPS</p></header>
<main>
<h1>Tu encaje con esta oferta</h1>
${r.ya_evaluada ? '<p class="aviso">Ya habías pegado esta oferta: te enseñamos la evaluación que hicimos entonces.</p>' : ''}
<article class="vac">
  <h2>${esc(v.puesto)}</h2>
  <p class="meta">${esc(v.empresa_nombre)} · ${esc(v.ubicacion || 'ubicación no consta')}</p>
  <div class="barra" aria-hidden="true"><span style="width:${Math.min(100, Math.max(0, pct(r.global)))}%"></span></div>
  <p class="nota"><strong>${pct(r.global)} % · ${nota(r.global)}/5</strong> <span class="banda banda-${BANDA[r.banda] || 'bajo'}">encaje ${BANDA[r.banda] || esc(r.banda)}</span></p>
  <ul class="dims">${DIM.map(([k, t]) => `<li>${t}: <strong>${r[k]}/5</strong></li>`).join('')}</ul>
  <p>${esc(r.explicacion).replace(/\n/g, '<br>')}</p>
  ${r.hueco ? `<p><strong>Para subir un punto:</strong> ${esc(r.hueco)}</p>` : ''}
  ${v.url_origen ? `<p><a href="${esc(v.url_origen)}" rel="noopener">Ver la oferta original</a></p>` : ''}
  ${pedir}
</article>
<p><a href="${N8N}/encaje?${firma}">Ver todas mis ofertas</a> · <a href="https://lanopsdmm.github.io/lanops/pegar-oferta/?${firma}">Pegar otra oferta</a></p>
</main>
<footer><p>% de congruencia = puntuación global × 20. La IA evalúa; tú decides. Rúbrica abierta de <a href="https://github.com/career-ops-hq/career-ops">career-ops</a> (MIT).</p></footer>
</body></html>`;
return [{ json: { html } }];
