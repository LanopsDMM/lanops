# LANOPS-ENCAJE (n8n)

Encaje a la medida (Pieza 5, dueño Marcos). El usuario abre su enlace firmado
`…/webhook/encaje?u=<id>&t=<firma>` (lo manda el correo de alta de `LANOPS-ALTA`, Pieza 6),
el flujo evalúa con Claude lo que falte y devuelve su lista en HTML.
Estado: todos los nodos `probado en simulación` (5-oct-2026: Postgres 16 local con las 261 vacantes reales
de Lanbide, firma HMAC con Node, respuestas de Claude simuladas). Falta la prueba con el modelo real en n8n.

Requisitos previos en Postgres: `norm.sql` ejecutado una vez; índice único
`evaluaciones (usuario, vacante, evaluador, hash_cv)`; CONFIGURACION `max_evaluaciones_por_ejecucion = 20`;
un evaluador IA activo con `modelo` y `prompt` = `motor/modes/_shared.md` + `motor/modes/oferta.md` + `envoltorio.md`.
Requisito en Railway: variable `ENCAJE_SECRET` (distinta de `CERT_SECRET`).

| # | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Webhook /encaje` | — | GET · Path `encaje` · Respond: Using 'Respond to Webhook' Node |
| 2 | `Crypto: firma` | — | Action Hmac · Type SHA256 · Value `encaje:{{ $json.query.u }}` · Secret `{{ $env.ENCAJE_SECRET }}` · Encoding HEX · Property Name `firma` |
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
| 12 | `Postgres: lista` | `lista.sql` | Execute Once ON · Always Output Data ON · entra desde 8 (true) y desde 11 |
| 13 | `Code: HTML` | `code-html.js` | Run Once for All Items |
| 14 | `Respond to Webhook` | — | Respond With Text · `{{ $json.html }}` · Header `Content-Type: text/html; charset=utf-8` |

Generar el enlace de un usuario (para pruebas o para `LANOPS-ALTA`): mismo nodo `Crypto` con
Value `encaje:<id>` y el mismo secreto; enlace = `<URL de producción del webhook>?u=<id>&t=<firma>`.

`ejemplo-lista.html`: cómo se ve la respuesta (datos simulados).
