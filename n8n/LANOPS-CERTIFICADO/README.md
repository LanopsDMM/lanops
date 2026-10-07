# LANOPS-CERTIFICADO (n8n)

Certificado de congruencia (Pieza 5, dueño Marcos). El usuario pulsa **Pedir certificado de esta vacante**
en su lista de ENCAJE; el enlace `…/webhook/certificar?u=<id>&t=<firma>&v=<vacante>` reutiliza la firma de su
enlace de ENCAJE (decisión 99). El flujo comprueba que se puede certificar, guarda el certificado en
`lanops.certificados` firmado con `CERT_SECRET` y devuelve la página del certificado con su QR.
El PDF es esa página impresa desde el navegador (decisión 5). Correo (Gmail, #4): versión posterior.

Estado: **[07-oct-2026] `probado en simulación`** (Postgres 16 local con el esquema `lanops`, los nodos ejecutados
tal cual con un simulador de n8n, firmas comprobadas contra `node:crypto`, página abierta en Chromium y QR leído
con un lector). Falta montarlo en n8n.

Reglas (decisiones 25, 54, 96–102):
- Lo puede pedir cualquier usuario, verificado o no; la página dice qué está verificado.
- Solo evaluaciones del evaluador IA activo con el CV actual, **banda Alta o Media**, vacante **abierta**.
- No se rehace la evaluación aunque tenga más de `reevaluar_si_dias`: el certificado muestra la fecha de la evaluación.
- Si ya hay un certificado vigente de esa evaluación, se devuelve el mismo (recargar no duplica).
- Caducidad = emisión + `caducidad_certificado_dias` (CONFIGURACION). Fechas en hora de Madrid.
- Firma = HMAC-SHA256(`CERT_SECRET`, `codigo|usuario|vacante|global con 2 decimales|fecha de emisión AAAA-MM-DD`).
  `LANOPS-VERIFICAR` la recalcula con el mismo formato (`../LANOPS-VERIFICAR/buscar.sql`).
- La página no muestra el "hueco" (qué le falta al usuario): es para él, no para la empresa.
- Lanbide no publica la empresa: sale "Empresa no publicada · oferta gestionada por Lanbide" (decisión 96).

Requisitos: variables `CERT_SECRET` y `ENCAJE_SECRET` en el servicio n8n (comprobado el 7-oct con
`LANOPS · prueba variables`: existe, 64 caracteres, distinto del de ENCAJE). `gen_random_uuid()` (Postgres ≥ 13).

| # | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Webhook /certificar` | — | GET · Path `certificar` · Respond: Using 'Respond to Webhook' Node |
| 2 | `Code: firma` | `../LANOPS-ENCAJE/code-firma.js` | Copiar el nodo de ENCAJE tal cual (Run Once for All Items) |
| 3 | `Code: entrada` | `code-entrada.js` | Run Once for All Items |
| 4 | `IF firma válida` | — | `{{ $json.valido }}` is true · rama false → `Respond 403` |
| 4b | `Respond 403` | — | Respond With Text · `Enlace no válido.` · Response Code 403 |
| 5 | `Postgres: preparar` | `preparar.sql` | Execute Query · Execute Once ON · Query Parameters (ver cabecera del archivo) |
| 6 | `Code: firmar` | `code-firmar.js` | Run Once for All Items |
| 7 | `Postgres: emitir` | `emitir.sql` | Execute Query · Execute Once ON · **Always Output Data ON** · Query Parameters `{{ [ JSON.stringify($json) ] }}` |
| 8 | `Code: QR` | `code-qr.js` | Run Once for All Items (lleva dentro la librería `qrcode-generator`, MIT) |
| 9 | `Code: HTML` | `code-html.js` | Run Once for All Items. Usa `$('Code: firmar')` y `$('Code: entrada')`: **los nombres de esos nodos deben ser exactos** |
| 10 | `Respond to Webhook` | — | Respond With Text · `{{ $json.html }}` · Header `Content-Type: text/html; charset=utf-8` · Options → Response Code `{{ $json.status }}` |

Respuestas: 200 certificado · 403 enlace no válido · 404 usuario o vacante inexistente ·
409 vacante cerrada, sin evaluación con el CV actual o banda Baja (la página dice cuál).

Probado en simulación (7-oct): emisión válida (firma = `node:crypto`, UUID, caducidad +30 días, 86 % · 4,30/5);
recargar no duplica; vacante de Lanbide (empresa no publicada, atribución, fecha de evaluación de hace 9 días);
banda Baja, vacante cerrada, inexistente, sin evaluación y usuario inexistente → no emiten; firma de otro usuario,
sin firma y `v` manipulado → 403; tras caducar uno, pedirlo emite uno nuevo. QR leído desde la página en Chromium =
`https://lanopsdmm.github.io/lanops/verificar/?c=<codigo>`.
