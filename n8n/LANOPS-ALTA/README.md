# LANOPS-ALTA (n8n)

Alta de usuarios (Pieza 6, dueño Javi). El botón "Crear mi perfil" de la landing lleva a
`https://lanopsdmm.github.io/lanops/alta/` (`lanops/alta/index.html`). Esa página envía el formulario
(multipart, con el PDF) a `https://n8n-production-3c20b.up.railway.app/webhook/alta`.

Estado: **[10-oct-2026] `probado en real`** (Javi). Alta de la persona demo Ane Etxeberria (ficticia, `ane.etxeberria@ejemplo.lanops.eus`, CV en PDF) desde `alta/index.html` con el email institucional `@alumni.tecnun.es`: usuario 202 creado, verificación de Tecnun en `pendiente`, 3 consejos sobre huecos del CV, y el enlace "Ver mis ofertas" abre su lista de ENCAJE (20 vacantes evaluadas). SQL probado también contra el esquema en un Postgres 16 local (alta y re-alta con el mismo email).

**Por qué Webhook y no Form Trigger [10-oct]:** la primera versión usaba un Form Trigger y una segunda página con las
preguntas (n8n Form). Con ella, Claude respondía y la ejecución quedaba esperando en "Form: preguntas", pero el
navegador mostraba "Problem submitting response". En producción no llegaba a crear ninguna ejecución. Causa no
confirmada. Se cambia al patrón de ENCAJE (Webhook + Respond to Webhook con HTML), que sí funciona en este servidor.
Las preguntas sobre el CV ("huecos") se enseñan al final como consejo, en vez de preguntarse.

| # | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Webhook /alta` | — | POST · Path `alta` · Respond: Using 'Respond to Webhook' Node |
| 2 | `Code: CV` | `code-cv.js` | renombra el PDF recibido a binario `cv` |
| 3 | `Extract from File: PDF` | — | Extract From PDF · Input Binary Field `cv` |
| 4 | `Code: petición 1` | `code-peticion-1.js` | prompt de la llamada 1 (skill, `prompts/alta-estructurar.md`) |
| 5 | `HTTP Request: Claude` | — | igual que en ENCAJE: POST `https://api.anthropic.com/v1/messages`, credencial Anthropic, cabecera `anthropic-version: 2023-06-01`, body `{{ $json.cuerpo }}`, Timeout 120000 |
| 6 | `Code: leer 1` | `code-leer-1.js` | CV estructurado + huecos |
| 7 | `Code: preparar` | `code-preparar.js` | lee `$('Webhook /alta')` y `$('Code: leer 1')`: **los nombres deben ser exactos**; campos = `name=` de `alta/index.html` |
| 8 | `Postgres: guardar` | `guardar.sql` | Execute Query · credencial Postgres · Query Parameters `{{ [ JSON.stringify($json.datos) ] }}` |
| 9 | `Code: enlace` | `code-enlace.js` | HMAC con `$env.ENCAJE_SECRET` (mismo cálculo que `LANOPS-ENCAJE/code-firma.js`) + página HTML final |
| 10 | `Respond to Webhook` | — | Text · `{{ $json.html }}` · cabecera `Content-Type: text/html; charset=utf-8` |
## Qué guarda

- **USUARIOS:** nombre y email del formulario; ciudad, titulación y `cv_texto` (sin DNI, fecha de nacimiento ni dirección) los saca Claude. `consentimiento_fecha` = ahora.
- **HABILIDADES / USUARIO_HABILIDAD:** se crean las habilidades que no existen; si dos se llaman igual salvo mayúsculas, se tratan como la misma.
- **PREFERENCIAS:** `puesto_objetivo` (peso 5) y los filtros `duro` (municipio, jornada, contrato salvo "Indiferente", salario mínimo y euskera salvo "No lo hablo"). Las exclusiones se guardan como `palabra`.
- **VERIFICACIONES:** si el dominio del email institucional (o, si no hay, del email) es el `dominio_email` de una ENTIDAD activa, se crea una verificación `email_institucional` en `pendiente` y el usuario pasa a `pendiente`. No hay correo para confirmarla.
- **Mismo email otra vez = editar el perfil** (decisión 116):
  - se reemplazan el CV, las habilidades y las preferencias `duro`/`peso`;
  - las exclusiones se suman, para no borrar lo que haya aprendido FEEDBACK;
  - un estado `pendiente`, `verificado` o `revocado` no baja.
  - Riesgo: quien conozca tu email puede cambiar tu perfil (no se confirma el email).

## Recomendaciones (LANOPS-INVITAR) [10-oct]

No hay un workflow aparte: va dentro del alta.
- **El código de cada usuario** es `R<id>-<8 hex>`, donde los 8 hex son los primeros de HMAC(`ENCAJE_SECRET`, `'recomienda:' + id`) en mayúsculas. **No se guarda en ninguna tabla**: `Code: preparar` lo comprueba recalculando la firma, así que no cambia la estructura congelada.
- **Dónde se ve el código:** en la página final del alta ("Recomienda a alguien"), con cuántas recomendaciones le quedan. También aparecen los enlaces a crear perfil y a pegar una oferta.
- **Cuándo cuenta la recomendación:** `Postgres: guardar` pone `usuarios.recomendado_por` solo si el que recomienda existe, no es la misma persona (otro email) y no ha llegado a `CONFIGURACION.cupo_recomendaciones` (3). Un `recomendado_por` ya guardado no cambia.
- **Si el código no vale** o se ha agotado el cupo, el alta se hace igual y se avisa al usuario.
- **`probado en real` [10-oct, Javi]:**
  - La re-alta de Ane (202) enseña su código `R202-63C7EABF`.
  - El alta de **Mikel Arrieta (demo)**, persona ficticia, usuario **204**, `mikel.arrieta@ejemplo.lanops.eus`, con ese código → "Has entrado recomendado/a por otra persona de LANOPS".
  - Antes se probó en Node (código válido, código falso, sin código) y en un Postgres 16 local: 3 recomendaciones aceptadas, la 4.ª rechazada y la auto-recomendación rechazada.

## Pendiente

- [10-oct] Texto completo de protección de datos en `lanops/privacidad/` (ítem 9); la casilla del alta enlaza a él.
- Si algo falla, n8n responde con su error genérico (no hay página de error propia).
- Preguntas sobre el CV en una segunda página (decisión 121): pendiente; ahora se enseñan como consejo.
