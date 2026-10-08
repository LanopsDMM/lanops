// n8n · workflow LANOPS-FEEDBACK · nodo "Code: preparar IA"  (detrás de "Postgres: aplicar")
// Modo: Run Once for All Items · JavaScript
// Decide si se pregunta a Claude qué regla aprender de este descarte y, si sí, arma la petición.
// Se pregunta SOLO si: es un descarte nuevo (no una recarga), con motivo, y la regla fija de la opción B no cubre el caso:
//   tarea · salario · lejos · otro → siempre
//   sector  → solo si no sabemos el sector de la empresa (p. ej. Lanbide)
//   empresa → solo si es de Lanbide (no publica la empresa)
// Sin motivo no se pregunta (el usuario solo quería quitarla) y no se gasta API.
// Salida: { pedir, cuerpo, regla: null, porque: null }. "IF ¿preguntar a la IA?" manda a Claude si pedir = true;
// si no, va directo a "Postgres: aprender" con regla = null.
const a = $input.first().json;
const pedir = a.accion === 'descartar' && a.nuevo === true && !!a.motivo && !!a.modelo && (
  ['tarea', 'salario', 'lejos', 'otro'].includes(a.motivo)
  || (a.motivo === 'sector' && !a.sector_tocado)
  || (a.motivo === 'empresa' && a.fuente === 'lanbide'));
if (!pedir) return [{ json: { pedir: false, regla: null, porque: null } }];

const MOTIVO = { tarea: 'lo que se hace en el puesto', sector: 'el sector', empresa: 'la empresa',
                 salario: 'el salario', lejos: 'está lejos', otro: 'otro motivo' };
const PROMPT = `Eres el módulo de aprendizaje de LANOPS, una plataforma de empleo de Gipuzkoa.
Un usuario acaba de descartar una oferta de su lista e indicó un motivo. Decide si de ese descarte se puede aprender
UNA regla de exclusión que le ahorre ver ofertas parecidas en el futuro, o si no hay ninguna regla clara.

Reglas posibles (solo estas):
- palabra: un término de 1 a 3 palabras que aparece TAL CUAL en el puesto o en la descripción de la oferta y que
  identifica el tipo de trabajo, tarea o condición que el usuario rechaza (p. ej. "teleoperador", "turno de noche",
  "carretillero", "a comisión"). Las ofertas cuyo texto contenga ese término dejarán de mostrarse.
- municipio: solo si el motivo es "está lejos". El municipio de la oferta, tal como aparece en su ubicación.
- contrato: solo si la oferta indica su tipo de contrato y el motivo apunta claramente a él. Valores: temporal, practicas, otro.

Criterios:
- Ante la duda, ninguna regla. Es mejor no aprender que aprender algo equivocado: una regla demasiado general
  escondería ofertas buenas.
- Nunca términos genéricos que salen en casi cualquier oferta: ingeniero/a, técnico/a, puesto, empresa, experiencia,
  empleo, trabajo, jornada, contrato, Gipuzkoa, nombres de municipio (para eso está "municipio"), idiomas, titulaciones.
- Nunca algo que contradiga lo que el usuario busca o sus no negociables, ni algo que ya excluya.
- Con "el salario" casi nunca hay regla: solo si el texto muestra una condición concreta (p. ej. "a comisión").
- Con "otro motivo" sé todavía más prudente.
- "porque" va dirigido al usuario: castellano, tuteo, una frase de 25 palabras como mucho. Si no hay regla, di en
  una frase por qué no.

Responde SOLO con este JSON, sin texto alrededor:
{"regla": {"clave": "palabra" | "municipio" | "contrato", "valor": "..."} | null, "porque": "..."}`;

const prefs = (typeof a.preferencias === 'string' ? JSON.parse(a.preferencias) : a.preferencias) || [];
const TIPO = { duro: 'no negociable', peso: 'preferencia', exclusion: 'ya excluye' };
const lineaPref = (p) => `- ${TIPO[p.tipo] || p.tipo} · ${p.clave} = ${p.valor}${p.tipo === 'peso' && p.peso ? ` (peso ${p.peso}/5)` : ''}`;
const fmt = (k, v) => `${k}: ${v === null || v === undefined || v === '' ? 'no consta' : v}`;
const texto = [
  '<perfil_de_busqueda>', prefs.map(lineaPref).join('\n') || '(sin preferencias)', '</perfil_de_busqueda>',
  '<oferta>', fmt('Puesto', a.puesto), fmt('Empresa', a.empresa), fmt('Ubicación', a.ubicacion), fmt('Contrato', a.contrato),
  'Descripción:', a.requisitos || 'no consta', '</oferta>',
  `<motivo>${MOTIVO[a.motivo]}</motivo>`,
].join('\n');

return [{ json: {
  pedir: true, regla: null, porque: null,
  cuerpo: {
    model: a.modelo,
    max_tokens: 2048,
    system: [{ type: 'text', text: PROMPT }],
    messages: [{ role: 'user', content: [{ type: 'text', text: texto }] }],
  },
}}];
