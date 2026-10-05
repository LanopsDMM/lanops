// n8n · workflow LANOPS-LANBIDE · nodo "Code: filtrar"
// Modo: Run Once for All Items · Lenguaje: JavaScript
// Entrada: salida del nodo "HTTP Request (JSON)" con Response Format = File
//          (propiedad binaria "data"). El JSON de Lanbide viene en ISO-8859-1.
// Salida: un item por vacante de Gipuzkoa, con los campos de lanops.vacantes.
//         hash, empresa, estado y vista_en NO se calculan aquí: los pone el SQL
//         (md5(codigo_externo), fila placeholder de EMPRESAS, 'abierta', CURRENT_DATE).

const PROVINCIA = 'GIPUZKOA';
const LINEA_DISC = 'Oferta reservada a personas con discapacidad.';

// 1. Leer y decodificar latin1
const buf = await this.helpers.getBinaryDataBuffer(0, 'data');
const ofertas = JSON.parse(buf.toString('latin1'));
if (!Array.isArray(ofertas)) throw new Error('Lanbide: se esperaba un array en la raíz');

// 2. Utilidades
const recorta = (s, n) => (s == null ? null : String(s).trim().slice(0, n) || null);
const fechaISO = (s) => {                      // 'dd/mm/aaaa' -> 'aaaa-mm-dd'
  const m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec((s || '').trim());
  return m ? `${m[3]}-${m[2]}-${m[1]}` : null;
};
const minus = (s) => (s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');

// Heurísticas sobre el texto libre (nulo si no se puede decidir; nunca adivinar)
const contrato = (t) => {
  const hits = [];
  if (/indefinid/.test(t)) hits.push('indefinido');
  if (/practicas|\bbeca\b/.test(t)) hits.push('practicas');
  if (/temporal|duracion determinada|sustitucion|obra y servicio|interinidad/.test(t)) hits.push('temporal');
  return hits.length === 1 ? hits[0] : null;   // 0 o varios -> nulo
};
const jornada = (t) => {
  const c = /jornada completa|tiempo completo|a jornada complet/.test(t);
  const p = /parcial|media jornada/.test(t);
  return c && !p ? 'completa' : p && !c ? 'parcial' : null;
};
const salarioMin = (t) => {                    // primer importe anual plausible
  for (const m of t.matchAll(/(\d{1,3}(?:\.\d{3})+|\d{5,6})(?:,\d{1,2})?/g)) {
    const n = parseInt(m[1].replace(/\./g, ''), 10);
    if (n >= 12000 && n <= 150000) return n;
  }
  return null;                                 // mensual, por hora o sin dato -> nulo
};

// 3. Filtrar y mapear
const salida = [];
for (const o of ofertas) {
  if ((o.provincia || '').trim().toUpperCase() !== PROVINCIA) continue;
  if (!o.codigo) continue;
  const texto = (o.desPuesto || '').trim();
  const t = minus(texto);
  const requisitos = o.disc === 'S' ? `${texto}\n${LINEA_DISC}` : texto;
  salida.push({ json: {
    codigo_externo: recorta(o.codigo, 30),
    puesto:         recorta(o.desEmpleo, 150),
    requisitos,
    contrato:       contrato(t),
    jornada:        jornada(t),
    ubicacion:      recorta(o.municipio, 60),
    salario_min:    salarioMin(t),
    fuente:         'lanbide',
    url_origen:     recorta(o.url, 255),
    fecha_pub:      fechaISO(o.fecPub),
  }});
}
if (salida.length === 0) throw new Error('Lanbide: 0 ofertas de Gipuzkoa; no se toca la base');
return salida;
