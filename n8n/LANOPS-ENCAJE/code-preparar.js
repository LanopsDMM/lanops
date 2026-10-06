// n8n · workflow LANOPS-ENCAJE · nodo "Code: preparar peticiones"
// Modo: Run Once for All Items · JavaScript
// Entrada: "Postgres: contexto" (1 item) + ítems de "Postgres: prefiltro".
// Salida: un item por vacante NO evaluada, con el cuerpo de la petición a la API de Claude.
// EVALUADORES.prompt = modes/_shared.md + modes/oferta.md + envoltorio.md (en ese orden).
const ctx = $('Postgres: contexto').first().json;
if (!ctx.prompt || !ctx.modelo) throw new Error('ENCAJE: no hay evaluador IA activo con prompt y modelo');
if (!ctx.cv_texto) throw new Error('ENCAJE: el usuario no tiene cv_texto');

const prefs = ctx.preferencias || [];
const lineaPref = (p) => `- ${p.tipo} · ${p.clave} = ${p.valor}${p.tipo === 'peso' && p.peso ? ` (peso ${p.peso})` : ''}`;
const perfil = `<perfil>\n${ctx.cv_texto}\n</perfil>\n\n<preferencias>\n${prefs.map(lineaPref).join('\n') || '(sin preferencias)'}\n</preferencias>`;

const vacantes = $('Postgres: prefiltro').all().map(i => i.json).filter(v => v.vacante && !v.evaluada);
// Sin pendientes: un único item marcador; el IF "¿hay pendientes?" lo manda directo a "Postgres: lista".
if (vacantes.length === 0) return [{ json: { sin_pendientes: true, usuario: ctx.usuario } }];
const fmt = (k, v) => (v === null || v === undefined || v === '' ? `${k}: no consta` : `${k}: ${v}`);

return vacantes.map(v => ({ json: {
  sin_pendientes: false, usuario: ctx.usuario, vacante: v.vacante, evaluador: ctx.evaluador, hash_cv: ctx.hash_cv,
  cuerpo: {
    model: ctx.modelo,
    max_tokens: 4096,   // [06-oct] 1024 se quedaba corto: el modelo piensa antes de responder y cortaba el JSON
    // Bloque fijo (career-ops + envoltorio): se cachea y se lee al 10 % en las llamadas siguientes.
    system: [{ type: 'text', text: ctx.prompt, cache_control: { type: 'ephemeral' } }],
    messages: [{ role: 'user', content: [
      // Perfil del usuario: igual en todas las vacantes de esta ejecución → segundo punto de caché.
      { type: 'text', text: perfil, cache_control: { type: 'ephemeral' } },
      { type: 'text', text: [
        '<vacante>',
        fmt('Puesto', v.puesto), fmt('Empresa', v.empresa_nombre), fmt('Ubicación', v.ubicacion),
        fmt('Contrato', v.contrato), fmt('Jornada', v.jornada),
        fmt('Salario mínimo anual', v.salario_min ? `${v.salario_min} €` : null),
        'Descripción:', v.requisitos || 'no consta',
        '</vacante>',
      ].join('\n') },
    ]}],
  },
}}));
