// n8n · workflow LANOPS-CERTIFICADO · nodo "Code: HTML"  (detrás de "Code: QR")
// Modo: Run Once for All Items · JavaScript
// Página del certificado (decisión 5: el PDF es esta página impresa) o, si no se puede emitir, el motivo.
// Accesible (decisión 21): HTML semántico, lang, contraste, la banda siempre con texto, QR con etiqueta.
// Muestra % = global × 20 junto a x/5 y las cinco dimensiones (decisión 26); qué está verificado (decisión 25);
// la fecha de la evaluación (decisión 102). El "hueco" (qué le falta) NO sale: es para el usuario, no para la empresa.
// [10-oct] Estilo común "Cálido" (decisiones 122–123): enlaza https://lanopsdmm.github.io/lanops/styles.css; sin <style> propio.
const r = $input.first().json;                       // datos del certificado (vacío si no se emite)
const pre = $('Code: firmar').first().json;          // motivo, banda, global
const ent = $('Code: entrada').first().json;         // usuario y firma del enlace, para volver a la lista
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const nota = (g) => Number(g).toFixed(2).replace('.', ',');
const pct = (g) => Math.round(Number(g) * 20);
const fecha = (iso) => { const [a, m, d] = String(iso || '').slice(0, 10).split('-'); return d ? `${d}/${m}/${a}` : ''; };
const BANDA = { Alta: 'alto', Media: 'medio', Baja: 'bajo' };
const DIM = [['d1_match_cv', 'Encaje con el CV'], ['d2_north_star', 'Alineación con lo que busca'],
             ['d3_compensacion', 'Compensación'], ['d4_cultura', 'Cultura y condiciones'],
             ['d5_red_flags', 'Alertas (5 = ninguna)']];
const volver = ent.usuario ? `encaje?u=${ent.usuario}&amp;t=${esc(ent.t)}` : null;

const pagina = (titulo, cuerpo) => `<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${esc(titulo)} · LANOPS</title>
<link rel="stylesheet" href="https://lanopsdmm.github.io/lanops/styles.css"></head><body>${cuerpo}</body></html>`;

if (!r.codigo) {
  const MOTIVO = {
    usuario: [404, 'No encontramos tu perfil.'],
    vacante: [404, 'Esa vacante no existe.'],
    vacante_cerrada: [409, 'Esta vacante ya está cerrada: no se puede certificar.'],
    sin_evaluacion: [409, 'Todavía no hay una evaluación de esta vacante con tu CV actual. Abre tu lista para que se evalúe.'],
    banda_baja: [409, `El encaje con esta vacante es bajo (${pre.global != null ? nota(pre.global) : '?'}/5). Solo se certifican encajes altos o medios.`],
  };
  const [status, texto] = MOTIVO[pre.motivo] || [500, 'No se ha podido emitir el certificado. Inténtalo de nuevo más tarde.'];
  const html = pagina('Certificado no disponible', `<header><p class="marca">LANOPS</p></header>
<main><h1>Certificado no disponible</h1>
<p>${esc(texto)}</p>${volver ? `<p><a href="${volver}">Volver a tu lista de vacantes</a></p>` : ''}</main>`);
  return [{ json: { html, status } }];
}

const verificado = r.titular_verificado
  ? `Perfil verificado${r.entidad ? ` por <strong>${esc(r.entidad)}</strong>` : ''}.`
  : 'Perfil sin verificar: LANOPS es de entrada abierta y la verificación es opcional.';
const html = pagina(`Certificado de ${r.titular}`, `
<div class="contenido solo-pantalla" role="note">
 <p><strong>Este certificado es tuyo:</strong> tú decides a quién se lo envías. Puedes mandar el enlace de verificación
 o guardarlo como PDF. Vale hasta el ${fecha(r.fecha_caducidad)}.</p>
 <p><button type="button" class="boton" onclick="window.print()">Imprimir o guardar como PDF</button>
 ${volver ? ` · <a href="${volver}">Volver a tu lista</a>` : ''}</p>
</div>
<main class="cert">
 <p class="marca">LANOPS</p>
 <h1>Certificado de congruencia con una vacante</h1>
 <p><strong>${esc(r.titular)}</strong>. ${verificado}</p>
 <h2>Vacante</h2>
 <p class="meta"><strong>${esc(r.puesto)}</strong><br>${esc(r.empresa)} · ${esc(r.ubicacion || 'ubicación no consta')}
 ${r.url_oferta ? `<br><a href="${esc(r.url_oferta)}" rel="noopener">Ver la oferta original</a>` : ''}</p>
 <h2>Resultado</h2>
 <div class="barra" aria-hidden="true"><span style="width:${Math.min(100, Math.max(0, pct(r.global)))}%"></span></div>
 <p class="nota"><strong>${pct(r.global)} % · ${nota(r.global)}/5</strong> <span class="banda banda-${BANDA[r.banda] || 'bajo'}">encaje ${BANDA[r.banda] || esc(r.banda)}</span></p>
 <ul>${DIM.map(([k, t]) => `<li>${t}: <strong>${esc(r[k])}/5</strong></li>`).join('')}</ul>
 <h2>Explicación del evaluador</h2>
 <p>${esc(r.explicacion).replace(/\n/g, '<br>')}</p>
 <h2>Datos del certificado</h2>
 <dl>
  <dt>Evaluado el</dt><dd>${fecha(r.fecha_evaluacion)}</dd>
  <dt>Rúbrica</dt><dd>${esc(r.version_rubrica)} · modelo ${esc(r.modelo)}</dd>
  <dt>Emitido el</dt><dd>${fecha(r.fecha_emision)}</dd>
  <dt>Válido hasta</dt><dd>${fecha(r.fecha_caducidad)}</dd>
  <dt>Código</dt><dd class="codigo">${esc(r.codigo)}</dd>
 </dl>
 <div class="qr">${r.qr_svg}
  <p>Para comprobar que es auténtico y sigue vigente, escanea el código o abre<br>
  <a class="codigo" href="${esc(r.url_verificacion)}">${esc(r.url_verificacion)}</a></p>
 </div>
</main>
<footer><p>% de congruencia = puntuación global × 20. La IA evalúa; la persona decide.
Puntuación con la rúbrica abierta de career-ops (MIT).${r.fuente === 'lanbide' ? ' Oferta: Fuente Lanbide / Open Data Euskadi (CC BY).' : ''}</p></footer>`);
return [{ json: { html, status: 200 } }];
