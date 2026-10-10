// n8n · workflow LANOPS-ALTA · nodo "Code: leer 1"
// Modo: Run Once for All Items · JavaScript
// Lee el JSON de Claude (CV estructurado + huecos). Los huecos ya no se preguntan en una segunda página
// (los formularios de varias páginas de n8n fallan en este servidor, 10-oct): se enseñan como consejo al final.
function leerJSON(respuesta) {
  const texto = (respuesta.content || []).filter(b => b.type === 'text').map(b => b.text).join('');
  const a = texto.indexOf('{'), z = texto.lastIndexOf('}');
  if (a < 0 || z < a) throw new Error('ALTA: Claude no ha devuelto JSON. Respuesta: ' + texto.slice(0, 300));
  return JSON.parse(texto.slice(a, z + 1));
}
const cv = leerJSON($input.first().json);
const huecos = (Array.isArray(cv.huecos) ? cv.huecos : []).map(String).filter(Boolean).slice(0, 3);
return [{ json: { cv, huecos } }];
