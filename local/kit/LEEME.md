# Kit de candidaturas de LANOPS (vía local)

LANOPS te dice **a qué vacantes encajas** y te da un certificado para demostrarlo. Este kit te ayuda con lo que viene
después: **llevar cada candidatura** desde tu ordenador, con un asistente de IA (Claude) y una carpeta de archivos tuya.

Nació antes que LANOPS: es el sistema con el que uno del equipo llevó una búsqueda de empleo real en el verano de 2026.
Aquí está **vacío**: solo las plantillas y las instrucciones. Nunca se sube aquí una carpeta rellena.

## Qué hace
- **Construye tu CV maestro entrevistándote**, pregunta a pregunta: trabajos cortos, logros medibles, cursos, idiomas
  con el nivel real… Todo lo que suele quedarse fuera del PDF.
- **Te propone empresas de una en una** con su ficha (puesto, enlace comprobado ese día, salario si se publica,
  qué cumples y qué no) y los cambios del CV para esa oferta. Respondes **A** (aceptar), **M** (modificar) o **R** (rechazar).
- **Prepara la candidatura** aceptada: CV adaptado desde el maestro y un dosier con el correo listo para copiar.
- **Lleva el registro**: estados, seguimientos a los 12 días, empresas descartadas y lo aprendido de cada fuente.

**Nada se envía solo.** Tú envías cada correo; el kit no marca nada como enviado sin que lo confirmes.

## Cómo empezar
1. Crea una carpeta para tu búsqueda (por ejemplo `mi-busqueda/`) y copia dentro el contenido de `plantillas/`.
2. Instala la skill de `skill/SKILL.md` en tu asistente (en Claude: Ajustes → Skills; en Claude Code, carpeta `.claude/skills/agente-busqueda-empleo/`).
3. Abre el asistente con esa carpeta conectada y pega el texto de `PRIMER_MENSAJE.md`.
4. Si tienes un CV antiguo, añádelo a la carpeta: la entrevista parte de él.

## Con LANOPS
- Usa **LANOPS en local** (https://github.com/LanopsDMM/motor/blob/main/README-es.md) o la web de LANOPS para saber a
  qué vacantes encajas; usa este kit para llevar esas candidaturas.
- Si tienes un **certificado de LANOPS** de una vacante, pon su enlace de verificación en el dosier de esa candidatura
  y en el correo: la empresa puede comprobarlo sin registrarse.

## Tus datos
- Todo vive en tu carpeta. **No subas tu carpeta rellena a ningún repositorio.**
- El CV maestro puede tener tu DNI, fecha de nacimiento y dirección para tu control, pero **nunca salen** en un CV enviado:
  solo ciudad, teléfono, correo y perfiles públicos.
- La sección privada de `perfil.md` (motivos de salida de cada empleo) es **opcional** y solo para preparar entrevistas.
  LANOPS no recoge ese dato.

Licencia: MIT, como el resto del repositorio `lanops`.
