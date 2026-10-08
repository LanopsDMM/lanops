# LANOPS-ENCAJE (n8n)

Encaje a la medida (Pieza 5, dueño Marcos). El usuario abre su enlace firmado
`…/webhook/encaje?u=<id>&t=<firma>` (lo manda el correo de alta de `LANOPS-ALTA`, Pieza 6),
el flujo evalúa con Claude lo que falte y devuelve su lista en HTML.
Estado: todos los nodos `probado en simulación` (5-oct-2026: Postgres 16 local con las 261 vacantes reales
de Lanbide, firma HMAC con Node, respuestas de Claude simuladas). Falta la prueba con el modelo real en n8n.
**[6-oct-2026] `probado en real` y publicado** (versión "Primera versión: encaje con Claude Sonnet 5.5"):
usuario sintético 1, 3 vacantes reales de Lanbide en Ordizia evaluadas por `claude-sonnet-5-5` (globales 1,4–1,6, banda Baja,
coherentes con su CV de Economía), guardadas en `lanops.evaluaciones`; página HTML servida por la Production URL
sin el editor abierto. Enlace malo → `403 Enlace no válido.` Caché de prompt verificado (`cache_read_input_tokens` > 0).
Coste observado: ~10 cts la primera evaluación con caché frío, ~2 cts las siguientes; 23 cts en total en las pruebas.
Cambios respecto al diseño del 5-oct: `Code: firma` en vez de Crypto (nodo 2); prefiltro acepta jornada `indiferente`;
`max_tokens` 4096 (con 1024 el razonamiento del modelo cortaba el JSON). Durante el montaje: fijar (*pin*) la salida de
`HTTP Request: Claude` para no gastar, y quitar el pin antes de publicar.
Limitación conocida: el municipio `duro` se filtra por nombre exacto; `radio_km` no se aplica en SQL.

Requisitos previos en Postgres: `norm.sql` ejecutado una vez; índice único
`evaluaciones (usuario, vacante, evaluador, hash_cv)`; CONFIGURACION `max_evaluaciones_por_ejecucion = 20`;
un evaluador IA activo con `modelo` y `prompt` = `motor/modes/_shared.md` + `motor/modes/oferta.md` + `envoltorio.md`.
Requisito en Railway: variable `ENCAJE_SECRET` (distinta de `CERT_SECRET`).

| # | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Webhook /encaje` | — | GET · Path `encaje` · Respond: Using 'Respond to Webhook' Node |
| 2 | `Code: firma` | `code-firma.js` | Run Once for All Items. [06-oct] Sustituye a `Crypto: firma`: en n8n 2.x el nodo Crypto pide el secreto en una credencial y no admite `$env`. Lee `$env.ENCAJE_SECRET` (requiere `N8N_BLOCK_ENV_ACCESS_IN_NODE=false`) y añade `firma` = HMAC-SHA256 hex de `encaje:<u>` |
| 3 | `Code: entrada` | `code-entrada.js` | Run Once for All Items |
| 4 | `IF firma válida` | — | `{{ $json.valido }}` es true · rama false → `Respond 403` |
| 4b | `Respond 403` | — | Respond With Text · `Enlace no válido.` · Response Code 403 |
| 5 | `Postgres: prefiltro` | `prefiltro.sql` | Execute Once ON · Always Output Data ON |
| 6 | `Postgres: contexto` | `contexto.sql` | Execute Once ON |
| 7 | `Code: preparar peticiones` | `code-preparar.js` | Run Once for All Items |
| 8 | `IF ¿hay pendientes?` | — | `{{ $json.sin_pendientes }}` es false → 9 · true → 12 |
| 9 | `HTTP Request: Claude` | — | POST `https://api.anthropic.com/v1/messages` · Predefined Credential Type → Anthropic (`Anthropic LANOPS`) · Header `anthropic-version: 2023-06-01` · Body JSON `{{ $json.cuerpo }}` · Options → Batching 1 item por lote · Timeout 120000 · Settings → On Error: Continue |
| 10 | `Code: leer evaluación` | `code-leer.js` | Run Once for All Items |
| 11 | `Postgres: guardar evaluaciones` | `insertar.sql` | Execute Once ON · Always Output Data ON |
| 12 | `Postgres: lista` | `lista.sql` | Execute Once ON · Always Output Data ON · entra desde 8 (true) y desde 11 · [08-oct] también quita lo que choca con una exclusión del usuario (las que aprende `LANOPS-FEEDBACK`) |
| 13 | `Code: HTML` | `code-html.js` | Run Once for All Items. [07-oct] Botón **Pedir certificado** en tarjetas Alta/Media → `certificar?u=&t=&v=` (decisiones 99–100; usa `$('Webhook /encaje')`: nombre exacto); empresa de Lanbide = "Empresa no publicada · oferta gestionada por Lanbide" (decisión 96); "encaje alto/medio/bajo" · [08-oct] formulario **No me interesa por … · Descartar** → `descartar?u=&t=&a=descartar&v=&m=` y enlace "Lo que LANOPS ha aprendido de ti" (`LANOPS-FEEDBACK`) |
| 14 | `Respond to Webhook` | — | Respond With Text · `{{ $json.html }}` · Header `Content-Type: text/html; charset=utf-8` |

Generar el enlace de un usuario (para pruebas o para `LANOPS-ALTA`): mismo código de `code-firma.js` con
`query.u = <id>` y el mismo secreto; enlace = `<URL de producción del webhook>?u=<id>&t=<firma>`.

`ejemplo-lista.html`: cómo se ve la respuesta (datos simulados).
