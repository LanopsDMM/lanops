// n8n · workflow LANOPS-ENCAJE · nodo "Code: entrada"  (detrás de "Crypto: firma")
// Modo: Run Once for All Items · JavaScript
// Comprueba el enlace firmado …/webhook/encaje?u=<id>&t=<firma>[&g=0]
// firma = HMAC-SHA256(ENCAJE_SECRET, 'encaje:' + id) en hex (la calcula "Crypto: firma").
const j = $input.first().json;
const q = j.query || {};
const u = String(q.u || '');
const valido = /^\d{1,9}$/.test(u) && typeof q.t === 'string'
  && q.t.length === 64 && q.t.toLowerCase() === String(j.firma || '').toLowerCase();
return [{ json: {
  valido,
  usuario: valido ? Number(u) : null,
  solo_gipuzkoa: q.g !== '0',          // por defecto, solo Gipuzkoa (decisión 31)
}}];
