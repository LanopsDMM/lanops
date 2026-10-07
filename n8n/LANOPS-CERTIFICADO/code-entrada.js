// n8n · workflow LANOPS-CERTIFICADO · nodo "Code: entrada"  (detrás de "Code: firma")
// Modo: Run Once for All Items · JavaScript
// Comprueba el enlace …/webhook/certificar?u=<id>&t=<firma>&v=<vacante>
// La firma es la MISMA del enlace de ENCAJE: HMAC-SHA256(ENCAJE_SECRET, 'encaje:' + id) en hex
// (decisión 99: el botón "Pedir certificado" de la lista reutiliza el enlace firmado del usuario).
const j = $input.first().json;
const q = j.query || {};
const u = String(q.u || '');
const v = String(q.v || '');
const valido = /^\d{1,9}$/.test(u) && /^\d{1,9}$/.test(v) && typeof q.t === 'string'
  && q.t.length === 64 && q.t.toLowerCase() === String(j.firma || '').toLowerCase();
return [{ json: {
  valido,
  usuario: valido ? Number(u) : null,
  vacante: valido ? Number(v) : null,
  t: valido ? q.t.toLowerCase() : null,   // para el enlace "volver a tu lista"
}}];
