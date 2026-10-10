// n8n · workflow LANOPS-ALTA · nodo "Code: preparar"
// Modo: Run Once for All Items · JavaScript
// Junta el CV estructurado ("Code: leer 1") y el formulario (body de "Webhook /alta") en un solo objeto
// para "Postgres: guardar". Los nombres de campo son los atributos name= de lanops/alta/index.html.
const f = $('Webhook /alta').first().json.body || {};
const cv = $('Code: leer 1').first().json.cv || {};

const txt = (v, n) => String(v ?? '').trim().slice(0, n);
const lista = (v) => String(v ?? '').split(/[,;\n]/).map(s => s.trim()).filter(Boolean);
if (String(f.consentimiento || '') !== 'si') throw new Error('ALTA: falta el consentimiento');
const email = txt(f.email, 150).toLowerCase();
if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new Error('ALTA: el email no es válido');
const institucional = txt(f.institucional, 150).toLowerCase();
const dominio = ((institucional || email).split('@')[1] || '').trim();

// Habilidades: categoría válida, nivel 1–5, nombre ≤ 60
const CATS = ['tecnica', 'idioma', 'transversal', 'herramienta'];
const habilidades = (Array.isArray(cv.habilidades) ? cv.habilidades : [])
  .map(h => ({
    nombre: txt(h.nombre, 60),
    categoria: CATS.includes(h.categoria) ? h.categoria : 'tecnica',
    nivel: Math.min(5, Math.max(1, parseInt(h.nivel, 10) || 2))
  }))
  .filter(h => h.nombre);

// Preferencias (claves de modelo-de-datos.md; valores como los usa el prefiltro de ENCAJE)
const pref = [];
const add = (tipo, clave, valor, peso = null) => {
  valor = txt(valor, 60);
  if (valor && !pref.some(p => p.tipo === tipo && p.clave === clave && p.valor.toLowerCase() === valor.toLowerCase())) {
    pref.push({ tipo, clave, valor, peso });
  }
};
add('peso', 'puesto_objetivo', f.puesto, 5);
for (const m of lista(f.municipios)) add('duro', 'municipio', m);
if (['completa', 'parcial', 'indiferente'].includes(f.jornada)) add('duro', 'jornada', f.jornada);
if (['indefinido', 'temporal', 'practicas'].includes(f.contrato)) add('duro', 'contrato', f.contrato);
const salario = parseInt(String(f.salario ?? '').replace(/\D/g, ''), 10);
if (salario > 0) add('duro', 'salario_min', String(salario));
if (/^[ABC][12]$/.test(f.euskera || '')) add('duro', 'euskera', f.euskera);
for (const x of lista(f.excluir)) add('exclusion', 'palabra', x);

return [{ json: { datos: {
  nombre: txt(f.nombre, 100) || txt(cv.nombre, 100),
  email,
  ciudad: txt(cv.ciudad, 60),
  titulacion: txt(cv.titulacion, 100),
  cv_texto: String(cv.cv_texto || '').trim(),
  dominio,
  habilidades,
  preferencias: pref
} } }];
