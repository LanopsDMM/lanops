// n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Code: vacante"
// Modo: Run Once for All Items · JavaScript
// Lee el JSON de la llamada 1 y prepara la fila de VACANTES (fuente 'usuario').
const texto = ($input.first().json.content || []).filter(b => b.type === 'text').map(b => b.text).join('');
const a = texto.indexOf('{'), z = texto.lastIndexOf('}');
if (a < 0 || z < a) throw new Error('PEGAR-OFERTA: Claude no ha devuelto JSON. Respuesta: ' + texto.slice(0, 300));
const o = JSON.parse(texto.slice(a, z + 1));
const e = $('Code: entrada').first().json;
const txt = (v, n) => String(v ?? '').trim().slice(0, n);
const contrato = ['indefinido', 'temporal', 'practicas', 'otro'].includes(o.contrato) ? o.contrato : null;
const jornada = ['completa', 'parcial'].includes(o.jornada) ? o.jornada : null;
const salario = parseInt(o.salario_min, 10);
const puesto = txt(o.puesto, 150) || 'Puesto sin título';
return [{ json: { datos: {
  puesto,
  empresa: txt(e.empresa_form || o.empresa, 100) || 'Empresa no indicada',
  ubicacion: txt(o.ubicacion, 60) || null,
  contrato, jornada,
  salario_min: salario > 0 ? salario : null,
  requisitos: txt(o.descripcion, 6000) || e.texto.slice(0, 6000),
  url_origen: e.url
} } }];
