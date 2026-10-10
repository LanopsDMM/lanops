// n8n · workflow LANOPS-ALTA · nodo "Code: petición 1"
// Modo: Run Once for All Items · JavaScript
// Prepara la llamada 1 a Claude: estructurar el CV y detectar huecos (prompt en la skill,
// references/prompts/alta-estructurar.md). El texto del CV viene de "Extract from File: PDF".
const MODELO = 'claude-sonnet-5-5';   // el mismo que el evaluador de ENCAJE
const texto = String($input.first().json.text || '').trim();
if (texto.length < 200) {
  throw new Error('ALTA: no se ha podido leer texto del PDF (¿es un escaneo?). Sube el CV exportado desde Word o similar.');
}
const SYSTEM = `Eres el módulo de alta de LANOPS, una red de empleo en Gipuzkoa. Recibes el texto de un CV.
Devuelve SOLO un JSON con esta forma:
{
  "nombre": "", "ciudad": "", "titulacion": "",
  "experiencias": [{"empresa":"", "puesto":"", "inicio":"AAAA-MM", "fin":"AAAA-MM|actual", "funciones":"", "logros":""}],
  "formacion_reglada": [{"titulo":"", "centro":"", "anio":""}],
  "formacion_no_reglada": [{"titulo":"", "entidad":"", "horas":""}],
  "habilidades": [{"nombre":"", "categoria":"tecnica|idioma|transversal|herramienta", "nivel":1-5, "evidencia":""}],
  "idiomas": [{"idioma":"", "nivel_real":"", "acreditacion":""}],
  "otros": {"carnet":"", "vehiculo":"", "disponibilidad":""},
  "cv_texto": "el CV reescrito en prosa limpia, sin DNI, fecha de nacimiento ni dirección postal",
  "huecos": ["pregunta 1", "pregunta 2", "pregunta 3"]
}
Reglas:
- No inventes nada. Si un dato no está, deja el campo vacío.
- No incluyas DNI, fecha de nacimiento ni dirección postal en ningún campo. Si vienen en el CV, ignóralos.
- \`nivel\` de una habilidad = nivel real de uso que el texto permite sostener, no el declarado. Si solo se menciona sin contexto, nivel 2 y \`evidencia\` vacía.
- \`huecos\`: máximo 3 preguntas, las más valiosas para el encaje, en este orden de prioridad: periodos sin explicar · puestos descritos en menos de dos líneas · idiomas sin nivel concreto · herramientas mencionadas sin contexto de uso · trabajos cortos, de verano, sin contrato o en negocio familiar que el CV pueda haber dejado fuera · logros medibles (cuánta gente, qué volumen, qué mejoró). Una pregunta por hueco, concreta, en tuteo. Si no hay huecos, lista vacía.`;
return [{ json: {
  cuerpo: {
    model: MODELO,
    max_tokens: 8000,   // el modelo piensa antes de responder y eso cuenta dentro del límite (decisión 92)
    system: SYSTEM,
    messages: [{ role: 'user', content: 'CV:\n\n' + texto.slice(0, 30000) }]
  }
} }];
