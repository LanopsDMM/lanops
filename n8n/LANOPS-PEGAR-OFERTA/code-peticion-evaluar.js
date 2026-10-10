// n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Code: petición evaluar"
// Modo: Run Once for All Items · JavaScript
// Llamada 2 a Claude: evaluar la vacante con el MISMO evaluador y formato que LANOPS-ENCAJE
// (code-preparar.js de ENCAJE, para una sola vacante). El prompt de career-ops sale de EVALUADORES.
const ctx = $('Postgres: contexto').first().json;
if (!ctx.prompt || !ctx.modelo) throw new Error('PEGAR-OFERTA: no hay evaluador IA activo con prompt y modelo');
const v = $input.first().json;                         // "Postgres: guardar vacante"
const prefs = ctx.preferencias || [];
const lineaPref = (p) => `- ${p.tipo} · ${p.clave} = ${p.valor}${p.tipo === 'peso' && p.peso ? ` (peso ${p.peso})` : ''}`;
const perfil = `<perfil>\n${ctx.cv_texto}\n</perfil>\n\n<preferencias>\n${prefs.map(lineaPref).join('\n') || '(sin preferencias)'}\n</preferencias>`;
const fmt = (k, x) => (x === null || x === undefined || x === '' ? `${k}: no consta` : `${k}: ${x}`);
return [{ json: {
  usuario: ctx.usuario, vacante: v.vacante, evaluador: ctx.evaluador, hash_cv: ctx.hash_cv,
  cuerpo: {
    model: ctx.modelo,
    max_tokens: 4096,
    system: [{ type: 'text', text: ctx.prompt, cache_control: { type: 'ephemeral' } }],
    messages: [{ role: 'user', content: [
      { type: 'text', text: perfil },
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
} }];
