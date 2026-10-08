// n8n · workflow LANOPS-FEEDBACK · nodo "Code: entrada"  (detrás de "Code: firma")
// Modo: Run Once for All Items · JavaScript
// Comprueba el enlace …/webhook/descartar?u=<id>&t=<firma>&a=<acción>[&v=<vacante>&m=<motivo>][&k=<clave>&val=<valor>]
// La firma es la MISMA del enlace de ENCAJE: HMAC-SHA256(ENCAJE_SECRET, 'encaje:' + id) en hex (como CERTIFICADO, decisión 99).
// Acciones:
//   descartar  v + m  → guarda el descarte y aprende (empresa al momento; sector a partir de N descartes)
//   recuperar  v      → borra el descarte: la oferta vuelve a la lista
//   olvidar    k + val → deja de excluir una empresa o un sector aprendido
//   ver               → solo enseña la página "Lo que LANOPS ha aprendido de ti"
// Sin "a": con v → descartar; sin v → ver.
const MOTIVOS = ['tarea', 'sector', 'empresa', 'salario', 'lejos', 'otro'];
const j = $input.first().json;
const q = j.query || {};
const u = String(q.u || '');
const firmaOk = /^\d{1,9}$/.test(u) && typeof q.t === 'string'
  && q.t.length === 64 && q.t.toLowerCase() === String(j.firma || '').toLowerCase();

const v = String(q.v || '');
let accion = String(q.a || (v ? 'descartar' : 'ver'));
let valido = firmaOk;
let vacante = null, motivo = null, clave = null, valor = null;

if (accion === 'descartar' || accion === 'recuperar') {
  if (/^\d{1,9}$/.test(v)) vacante = Number(v); else valido = false;
  if (accion === 'descartar') motivo = MOTIVOS.includes(q.m) ? q.m : 'otro';   // sin motivo → "otro" (no aprende nada)
} else if (accion === 'olvidar') {
  clave = ['empresa', 'sector'].includes(q.k) ? q.k : null;
  valor = typeof q.val === 'string' ? q.val.trim().slice(0, 60) : '';
  if (!clave || !valor) valido = false;
} else if (accion !== 'ver') {
  valido = false;
}

return [{ json: {
  valido,
  usuario: valido ? Number(u) : null,
  t: valido ? q.t.toLowerCase() : null,   // para los enlaces y formularios de la página
  accion: valido ? accion : null,
  vacante, motivo, clave, valor,
}}];
