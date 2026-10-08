// n8n · workflow LANOPS-FEEDBACK · nodo "Code: entrada"  (detrás de "Code: firma")
// Modo: Run Once for All Items · JavaScript
// Comprueba el enlace …/webhook/descartar?u=<id>&t=<firma>&a=<acción>[&v=<vacante>&m=<motivo>][&k=<clave>&val=<valor>]
// La firma es la MISMA del enlace de ENCAJE: HMAC-SHA256(ENCAJE_SECRET, 'encaje:' + id) en hex (como CERTIFICADO, decisión 99).
// Acciones:
//   descartar  v [+ m] → guarda el descarte; con motivo, LANOPS puede aprender una regla (opción B + IA, 08-oct)
//   recuperar  v       → borra el descarte: la oferta vuelve a la lista
//   olvidar    k + val → quita una regla APRENDIDA (empresa, sector, palabra, municipio o contrato)
//   ver                → solo enseña la página "Lo que LANOPS ha aprendido de ti"
// Sin "a": con v → descartar; sin v → ver. El motivo es OPCIONAL: sin motivo (o uno no válido) solo se quita la oferta.
// x = el porqué en palabras del usuario: solo con "otro motivo" y obligatorio (sin él → accion "falta_porque", no se descarta).
const MOTIVOS = ['tarea', 'sector', 'empresa', 'salario', 'lejos', 'otro'];
const CLAVES = ['empresa', 'sector', 'palabra', 'municipio', 'contrato'];
const j = $input.first().json;
const q = j.query || {};
const u = String(q.u || '');
const firmaOk = /^\d{1,9}$/.test(u) && typeof q.t === 'string'
  && q.t.length === 64 && q.t.toLowerCase() === String(j.firma || '').toLowerCase();

const v = String(q.v || '');
let accion = String(q.a || (v ? 'descartar' : 'ver'));
let valido = firmaOk;
let vacante = null, motivo = null, clave = null, valor = null, texto = '';

if (accion === 'descartar' || accion === 'recuperar') {
  if (/^\d{1,9}$/.test(v)) vacante = Number(v); else valido = false;
  if (accion === 'descartar') {
    motivo = MOTIVOS.includes(q.m) ? q.m : null;
    // El porqué en palabras del usuario: SOLO con "otro motivo", y entonces obligatorio. ≤ 200 caracteres,
    // sin saltos ni caracteres de control. NO se guarda. Con cualquier otro motivo se ignora.
    if (motivo === 'otro') {
      texto = typeof q.x === 'string' ? q.x.replace(/[\u0000-\u001f\u007f]+/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 200) : '';
      if (!texto) accion = 'falta_porque';   // no se descarta: la página pide el porqué
    }
  }
} else if (accion === 'olvidar') {
  clave = CLAVES.includes(q.k) ? q.k : null;
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
  texto,   // solo para la IA ("Code: preparar IA"); aplicar.sql lo ignora
}}];
