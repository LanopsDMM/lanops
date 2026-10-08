// n8n · workflow LANOPS-FEEDBACK · nodo "Code: leer regla"  (detrás de "HTTP Request: Claude")
// Modo: Run Once for All Items · JavaScript
// Lee la regla que propone Claude y la VALIDA antes de dejarla pasar: la IA propone, el código decide.
// Si algo no cuadra, regla = null (no se aprende nada) y el descarte sigue guardado.
// Salida: { regla: {clave, valor} | null, porque, ia_error }
const a = $('Postgres: aplicar').first().json;
const r0 = $input.first().json;
const norm = (s) => String(s ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/\s+/g, ' ').trim();
const GENERICAS = ['ingeniero', 'ingeniera', 'ingenieria', 'tecnico', 'tecnica', 'puesto', 'empresa', 'experiencia',
  'empleo', 'trabajo', 'jornada', 'contrato', 'gipuzkoa', 'guipuzcoa', 'oferta', 'persona', 'personas', 'candidato',
  'candidata', 'grado', 'titulacion', 'formacion', 'ingles', 'euskera', 'castellano', 'equipo', 'proyecto', 'proyectos',
  'cliente', 'clientes', 'funciones', 'requisitos', 'se requiere', 'se ofrece', 'buscamos', 'incorporacion'];

const prefs = (typeof a.preferencias === 'string' ? JSON.parse(a.preferencias) : a.preferencias) || [];
const texto = norm(`${a.puesto || ''} ${a.requisitos || ''}`);
const busca = prefs.filter(p => p.tipo !== 'exclusion').map(p => norm(p.valor));

function validar(regla) {
  if (!regla) return 'sin regla';
  const clave = String(regla.clave || ''), valor = norm(regla.valor);
  if (!['palabra', 'municipio', 'contrato'].includes(clave)) return `clave no permitida: ${clave}`;
  if (prefs.some(p => p.tipo === 'exclusion' && p.clave === clave && norm(p.valor) === valor)) return 'ya la excluía';
  if (clave === 'palabra') {
    if (valor.length < 3 || valor.length > 40 || valor.split(' ').length > 3) return 'palabra de longitud no válida';
    if (GENERICAS.includes(valor)) return 'palabra demasiado genérica';
    if (!texto.includes(valor)) return 'la palabra no aparece en la oferta';
    if (norm(a.ubicacion).includes(valor)) return 'es un municipio: no va como palabra';
    if (busca.some(b => b.includes(valor) || (b.length >= 4 && valor.includes(b)))) return 'choca con lo que busca el usuario';
  }
  if (clave === 'municipio') {
    if (a.motivo !== 'lejos') return 'municipio solo con el motivo "está lejos"';
    if (valor.length < 3 || !norm(a.ubicacion).includes(valor)) return 'el municipio no es el de la oferta';
    if (prefs.some(p => p.tipo === 'duro' && p.clave === 'municipio' && norm(p.valor) === valor)) return 'es su municipio no negociable';
  }
  if (clave === 'contrato') {
    if (!['temporal', 'practicas', 'otro'].includes(valor)) return 'tipo de contrato no válido';
    if (a.contrato && a.contrato !== valor) return 'no es el contrato de la oferta';
    if (prefs.some(p => p.tipo === 'duro' && p.clave === 'contrato' && norm(p.valor) === valor)) return 'es un contrato que el usuario acepta como no negociable';
  }
  return null;
}

let regla = null, porque = null, ia_error = null;
try {
  if (r0.error) throw new Error(typeof r0.error === 'string' ? r0.error : JSON.stringify(r0.error).slice(0, 300));
  const t = (r0.content || []).filter(b => b.type === 'text').map(b => b.text).join('').trim()
    .replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
  const r = JSON.parse(t.slice(t.indexOf('{'), t.lastIndexOf('}') + 1));
  porque = String(r.porque || '').slice(0, 300) || null;
  const motivoRechazo = validar(r.regla);
  if (motivoRechazo === null) regla = { clave: r.regla.clave, valor: norm(r.regla.valor).slice(0, 60) };
  else if (r.regla) { ia_error = `regla descartada por la validación: ${motivoRechazo}`; porque = null; }
} catch (e) {
  ia_error = String(e.message || e).slice(0, 300);
}
return [{ json: { regla, porque, ia_error } }];
