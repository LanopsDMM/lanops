// n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Code: petición extraer"
// Modo: Run Once for All Items · JavaScript
// Llamada 1 a Claude: convertir el texto pegado en los campos de VACANTES.
const ctx = $input.first().json;                       // "Postgres: contexto"
if (!ctx.usuario) throw new Error('PEGAR-OFERTA: el usuario no existe');
if (!ctx.cv_texto) throw new Error('PEGAR-OFERTA: el usuario no tiene CV (cv_texto vacío)');
const e = $('Code: entrada').first().json;
const SYSTEM = `Eres el módulo "pegar una oferta" de LANOPS. Recibes el texto de una oferta de empleo copiado de cualquier sitio.
Devuelve SOLO un JSON con esta forma:
{"puesto":"", "empresa":"", "ubicacion":"", "contrato":"indefinido|temporal|practicas|otro|", "jornada":"completa|parcial|", "salario_min":0, "descripcion":""}
Reglas:
- No inventes nada. Si un dato no está, deja "" (o 0 en salario_min).
- puesto: el título del puesto, máximo 150 caracteres.
- empresa: el nombre de la empresa que contrata (no el portal). Si es una ETT, el nombre de la ETT.
- ubicacion: municipio, máximo 60 caracteres.
- salario_min: salario bruto anual mínimo en euros, entero. Si viene mensual, multiplícalo por 14 solo si el texto dice 14 pagas; si no, por 12.
- descripcion: el texto de la oferta limpio (funciones, requisitos, condiciones), sin publicidad del portal ni avisos de cookies, máximo 6000 caracteres.`;
return [{ json: { cuerpo: {
  model: ctx.modelo || 'claude-sonnet-5-5',
  max_tokens: 8000,
  system: SYSTEM,
  messages: [{ role: 'user', content: (e.empresa_form ? 'Empresa (indicada por el usuario): ' + e.empresa_form + '\n\n' : '') + 'Oferta:\n\n' + e.texto }]
} } }];
