// n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Code: leer evaluación"
// Modo: Run Once for All Items · JavaScript
// Igual que LANOPS-ENCAJE/code-leer.js para una sola respuesta: valida d1–d5 y global,
// calcula global_personal con los pesos del usuario y la banda con los umbrales de CONFIGURACION.
const ctx = $('Postgres: contexto').first().json;
const pedida = $('Code: petición evaluar').first().json;
const alta  = Number(ctx.umbral_alta  ?? 4);
const media = Number(ctx.umbral_media ?? 3);
const MAPA = {
  d1_match_cv:     ['euskera', 'idioma'],
  d2_north_star:   ['puesto_objetivo', 'sector', 'situacion_actual'],
  d3_compensacion: ['salario_min'],
  d4_cultura:      ['estabilidad', 'modalidad', 'tamano', 'turnos', 'jornada', 'contrato',
                    'municipio', 'radio_km', 'movilidad', 'fecha_inicio_max'],
  d5_red_flags:    ['ett', 'empresa', 'palabra', 'permiso_trabajo'],
};
const pesos = (ctx.preferencias || []).filter(p => p.tipo === 'peso' && p.peso);
const pesoDim = Object.fromEntries(Object.entries(MAPA).map(([d, claves]) => {
  const ws = pesos.filter(p => claves.includes(p.clave)).map(p => Number(p.peso));
  return [d, ws.length ? Math.max(...ws) : 3];
}));
const DIM = Object.keys(MAPA);
const entero15 = (x) => Number.isInteger(x) && x >= 1 && x <= 5;

const texto = ($input.first().json.content || []).filter(b => b.type === 'text').map(b => b.text).join('').trim();
const limpio = texto.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
const r = JSON.parse(limpio.slice(limpio.indexOf('{'), limpio.lastIndexOf('}') + 1));
for (const d of DIM) if (!entero15(r[d])) throw new Error(`PEGAR-OFERTA: ${d} fuera de 1–5: ${r[d]}`);
const g = Number(r.global);
if (!(g >= 1 && g <= 5)) throw new Error(`PEGAR-OFERTA: global fuera de 1–5: ${r.global}`);
const sumW = DIM.reduce((s, d) => s + pesoDim[d], 0);
const gp = DIM.reduce((s, d) => s + r[d] * pesoDim[d], 0) / sumW;
return [{ json: {
  usuario: pedida.usuario, vacante: pedida.vacante, evaluador: pedida.evaluador, hash_cv: pedida.hash_cv, ok: true,
  d1_match_cv: r.d1_match_cv, d2_north_star: r.d2_north_star, d3_compensacion: r.d3_compensacion,
  d4_cultura: r.d4_cultura, d5_red_flags: r.d5_red_flags,
  global: Math.round(g * 10) / 10,
  global_personal: Math.round(gp * 10) / 10,
  banda: g >= alta ? 'Alta' : g >= media ? 'Media' : 'Baja',
  explicacion: String(r.explicacion || '').slice(0, 2000),
  hueco: String(r.hueco || '').slice(0, 1000)
} }];
