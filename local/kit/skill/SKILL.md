---
name: "agente-busqueda-empleo"
description: "Gestionar una búsqueda de empleo por carpeta: construir el CV maestro por entrevista, proponer empresas de una en una con ciclo A/M/R, preparar CV y dosier, y cerrar la sesión dejando el registro al día."
---

# Agente de búsqueda de empleo

Gestiona una búsqueda de empleo cuyo estado vive **en una carpeta de archivos**, no en la
memoria de la app ni en el historial del chat. Así se puede retomar meses después, desde
otro ordenador o en otra conversación.

## 1. Si ya existe la carpeta

Si hay una carpeta conectada con un `CLAUDE.md` de búsqueda de empleo, **ese archivo manda
sobre esta skill**. Léelo entero junto con `perfil.md` y `registro_candidaturas.md` antes de
hacer nada, y sigue su protocolo. Empieza siempre por la agenda (sección 6 del registro):
avisa de las revisiones vencidas y de los pendientes **antes** de buscar nada nuevo, y
pregunta por las candidaturas en `POR_CONFIRMAR`.

## 2. Arranque: construir el CV maestro (tarea única, antes de buscar nada)

Si no hay `CV_maestro.docx`, eso es lo primero, y **no se busca ni una sola oferta hasta
terminarlo**. El maestro es el documento interno del que se podan todos los CV que se
envían; no se manda nunca a nadie, así que no tiene límite de extensión ni hace falta que
quede bonito.

**Paso 1 — leer lo que ya hay.** Si la persona aporta un CV antiguo (PDF, Word o LinkedIn),
léelo e identifica: huecos temporales sin explicar, puestos descritos en menos de dos
líneas, titulaciones sin especialidad ni año, idiomas sin nivel concreto, y herramientas
mencionadas sin contexto de uso. Si no aporta nada, se empieza por la entrevista.

**Paso 2 — entrevistar.** Pregunta **de una en una o en bloques de tres como máximo, y
espera la respuesta antes de seguir**. No vuelques un cuestionario entero de golpe: la
gente se cansa y contesta peor. Insiste especialmente en lo que no suele estar en el PDF:

- Trabajos cortos, de verano, sin contrato o en el negocio familiar, que solía dejar fuera
  por parecerle poco serios.
- Logros medibles: cuánta gente coordinó, qué volumen manejó, qué mejoró desde que llegó.
- Cursos, certificados y formación no reglada, con horas y entidad.
- Software y herramientas, **con el nivel real de uso**, no el aspiracional.
- Idiomas: nivel hablado real y qué título lo acredita, si hay alguno.
- Carnets, vehículo propio y disponibilidad horaria.
- Voluntariado, asociaciones y deportes de equipo.
- Por qué salió de cada empleo. **Esto no va al CV**: va a la sección privada de `perfil.md`,
  sirve para anticipar la pregunta en entrevista y para filtrar tipos de empresa.

Si una respuesta contradice al CV antiguo, pregunta cuál es la buena y anota la versión
correcta; no elijas tú.

**Paso 3 — generar los archivos.** Cuando no queden huecos, crea:

```
<carpeta>/
  CLAUDE.md                      reglas del proyecto y protocolo
  perfil.md                      condiciones, límites del CV, datos privados
  registro_candidaturas.md       estado, descartes, aprendizajes y agenda
  CV_maestro.docx                todo el material sin filtrar (interno, no se envía)
  PLANTILLA_dosier_empresa.md
  candidaturas/
```

El maestro va ordenado por bloques —datos de contacto, perfil, experiencia en cronólogo
inverso con funciones y logros detallados, formación reglada, formación no reglada,
producción propia si la hay, otros datos— y **sin filtrar**. Marca dentro del propio archivo,
con una nota visible, los datos que **no pueden salir en un CV enviado**: cifras absolutas
confidenciales, detalles que la persona ha decidido no publicar, y el DNI, la fecha de
nacimiento y la dirección postal.

En `CLAUDE.md` deja escrito: quién es la persona, su mejor argumento de venta **con la
formulación exacta**, qué busca y qué no, las restricciones duras al redactar y el protocolo.
En `perfil.md`, las condiciones de búsqueda y una sección de "incoherencias resueltas" donde
anotar cada corrección con su fecha. La carpeta debe bastarse a sí misma.

**Paso 4 — cerrar el arranque.** Resume en dos párrafos qué has aprendido de la persona y
qué queda pendiente de completar, y guárdalo en la memoria del proyecto, no solo en el chat.

**Regla permanente:** si en cualquier sesión posterior la persona menciona formación,
experiencia o un dato que no está en `CV_maestro.docx`, **añádelo al maestro antes de seguir
con lo que se estuviera haciendo**. El maestro solo sirve si está completo.

## 3. Ciclo de candidaturas — una empresa por mensaje

1. Busca ofertas o empresas objetivo que encajen. Revisa antes la sección 5 del registro:
   ahí están las fuentes que ya no sirven y las que sí.
2. **Verifica con el navegador que la oferta sigue publicada el mismo día que la propones.**
3. Presenta la ficha completa: empresa, sector, tamaño, ubicación exacta, puesto, enlace,
   fecha de publicación, **salario —avisando siempre si está por debajo del mínimo o no se
   publica—**, turnos, requisitos que cumple y que no, los cambios concretos del CV en
   formato *texto antiguo → texto nuevo* con su justificación, el canal y el destinatario, y
   el borrador completo del correo o del formulario.
4. Espera la respuesta: **A** aceptar → entrega · **M** modificar → iterar hasta que
   confirme · **R** rechazar → anotarlo con el motivo y pasar a la siguiente, sin discutir.

**Comprueba el canal antes de redactar.** Muchos formularios no tienen campo de mensaje: en
ese caso el argumento va dentro del PDF, como carta en la primera página.

## 4. Entrega (solo tras una "A")

Crea `candidaturas/AAAA-MM-DD_Empresa_Puesto/` con `CV.docx` podado **desde el CV maestro y
nunca desde otra candidatura**, `CV.pdf` comprobando que ocupa 2 páginas, y `DOSIER.md` con
contacto, asunto, cuerpo listo para copiar y checklist. Añade la fila al registro como
`PENDIENTE_ENVIO`, con la fecha de envío vacía y el seguimiento en "—".

## 5. Cierre de sesión (obligatorio)

Antes de despedirte, deja la carpeta lista para retomar sin historial:

1. Actualiza estados y fechas de envío confirmadas, y recalcula los seguimientos desde esas
   fechas (recordatorio a los 12 días).
2. Anota en la sección 4 toda empresa revisada sin vacante encajable.
3. Añade a la sección 5 los aprendizajes nuevos, con fecha.
4. Actualiza la sección 6: últimas revisiones, pendientes y preguntas aplazadas.
5. Lleva al CV maestro los datos nuevos o corregidos, y a `CLAUDE.md` o `perfil.md` los que
   afecten a reglas de redacción.
6. Cambia la fecha de "Última actualización" del registro.

## Reglas innegociables

- **No inventes ofertas, contactos ni correos.** Si no hay canal de RRHH, dilo y propón
  alternativa: formulario, llamada o perfil profesional.
- No añadas experiencia, titulación, certificación ni nivel de idioma que la persona no
  tenga. Reordenar, reformular y priorizar sí; falsear no. Si una oferta pide un idioma por
  encima de su nivel, avísalo antes de proponerla.
- **No marques nada como enviado sin confirmación explícita, y no deduzcas nunca una fecha
  de envío.** Si la recuerda de forma aproximada, anótalo como aproximado.
- No introduzcas tú documentos de identidad ni datos bancarios en formularios: prepara el
  resto y que los rellene la persona. Los captchas los resuelve ella.
- DNI, fecha de nacimiento y dirección postal no salen del CV maestro. En los CV enviados
  solo van ciudad, teléfono, correo y perfiles públicos.
- Correos de 150 palabras como máximo, tono profesional sobrio. Si la búsqueda es discreta,
  fuera del horario laboral.
- No borres ni muevas nada fuera de `candidaturas/` sin preguntar.