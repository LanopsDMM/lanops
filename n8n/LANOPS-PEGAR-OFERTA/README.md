# LANOPS-PEGAR-OFERTA (n8n)

"Pegar una oferta" (Pieza 6, dueño Javi). El botón de la landing lleva a `https://lanopsdmm.github.io/lanops/pegar-oferta/`
(`lanops/pegar-oferta/index.html`). Esa página envía el formulario (POST) a
`https://n8n-production-3c20b.up.railway.app/webhook/pegar-oferta`. Mismo patrón que `LANOPS-ALTA` (decisión 126):
página propia en Pages + Webhook + Respond to Webhook con HTML.

Estado: **[10-oct-2026] `construido`**. El SQL está probado contra el esquema en un Postgres 16 local (vacante nueva, la misma oferta dos veces, empresa nueva y empresa existente; evaluación nueva y repetida). La firma del enlace está comprobada contra `node:crypto`. No está probado en n8n.

## Quién es el usuario

Con su **enlace personal de ENCAJE** (`?u=<id>&t=<firma>`, decisión 63):
- si la página se abre con `?u=&t=` (por ejemplo desde la página final de PEGAR-OFERTA, "Pegar otra oferta"), van ocultos;
- si no, el usuario pega su enlace entero en el campo "Tu enlace personal" y `Code: entrada` saca `u` y `t` de él (funciona sin JavaScript).

La firma se comprueba igual que en `LANOPS-ENCAJE/code-firma.js`.

## Flujo

| # | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Webhook /pegar-oferta` | — | POST · Path `pegar-oferta` · Respond: Using 'Respond to Webhook' Node |
| 2 | `Code: entrada` | `code-entrada.js` | `u`/`t` (o `enlace`), firma con `$env.ENCAJE_SECRET`, texto ≥ 200 caracteres |
| 3 | `IF entrada válida` | — | `{{ $json.valido }}` es true · false → 15 |
| 4 | `Postgres: contexto` | `contexto.sql` | igual que en ENCAJE · Query Parameters `{{ [ $('Code: entrada').first().json.usuario ] }}` |
| 5 | `Code: petición extraer` | `code-peticion-extraer.js` | Claude convierte el texto en puesto, empresa, ubicación, contrato, jornada, salario y descripción |
| 6 | `HTTP Request: Claude extraer` | — | como en ENCAJE (credencial Anthropic, `anthropic-version`, Timeout 120000) |
| 7 | `Code: vacante` | `code-vacante.js` | fila de VACANTES |
| 8 | `Postgres: guardar vacante` | `guardar-vacante.sql` | empresa por nombre (o nueva, anillo 1, `tipo_lectura='manual'`) · VACANTES `fuente='usuario'` · [12-oct] misma oferta = misma empresa + mismo puesto + mismo enlace sin `?…` (o mismo texto pegado normalizado) → se reutiliza la vacante · devuelve `ya_evaluada` y, si es true, la evaluación previa |
| 8b | `IF ya evaluada` | — | [12-oct] `{{ $json.ya_evaluada }}` is true → **true: 13 `Code: HTML`** (sin llamar a Claude; aviso "Ya habías pegado esta oferta") · false: 9 |
| 9 | `Code: petición evaluar` | `code-peticion-evaluar.js` | mismo evaluador, prompt y formato que ENCAJE |
| 10 | `HTTP Request: Claude evaluar` | — | como el 6 |
| 11 | `Code: leer evaluación` | `code-leer-evaluacion.js` | como `ENCAJE/code-leer.js` (pesos del usuario, umbrales de banda) |
| 12 | `Postgres: guardar evaluación` | `guardar-evaluacion.sql` | INSERT en EVALUACIONES; si ya existía (misma oferta, mismo CV) no se toca y se devuelve la existente (puede tener certificado) |
| 13 | `Code: HTML` | `code-html.js` | la tarjeta de ENCAJE + "Pedir certificado" (solo Alta/Media) + "Ver todas mis ofertas" + "Pegar otra oferta" |
| 14 | `Respond to Webhook` | — | Text · `{{ $json.html }}` · `Content-Type: text/html; charset=utf-8` |
| 15 | `Code: página de error` | `code-error.js` | enlace no válido o texto corto |
| 16 | `Respond error` | — | como el 14, código 400 |

## A tener en cuenta

- ~~Una oferta pegada queda en VACANTES como `abierta`, con anillo 1, así que **también aparece en las listas de ENCAJE de los demás usuarios**.~~ [12-oct] **Las ofertas pegadas son privadas**: `LANOPS-ENCAJE/prefiltro.sql` excluye `fuente='usuario'`, así que solo las evalúa (y las ve) quien las pega, como dice la memoria. Motivos: una oferta falsa o inexacta no llega a nadie más y una empresa no puede publicar la suya de forma encubierta. Nada la cierra después (pendiente: caducidad).
- Cada oferta pegada son 2 llamadas a Claude; [12-oct] si el usuario ya la tenía evaluada con su CV actual, solo 1 (extraer). La extracción no se evita: sin saber la empresa, el enlace solo no basta (una web de empleo puede tener una sola página para todas sus ofertas).
- `Code: vacante` [12-oct] añade a `datos` `texto_pegado`, `usuario`, `hash_cv` y `evaluador`. La huella usa el texto pegado, no la descripción de Claude, que cambia en cada llamada.
- `url_origen` es varchar(255): un enlace más largo se guarda sin `?…`.
