# LANOPS-FEEDBACK (n8n)

Lo que LANOPS aprende de los descartes (Pieza 5, dueño Marcos; 08-oct-2026: opción B + IA, sin tocar pesos).
En cada tarjeta de la lista de ENCAJE hay un desplegable **"No me interesa"** (motivo, con "solo quitarla" por defecto; "Cuéntanos por qué"; Descartar): la oferta sale
de la lista y, si hay motivo, LANOPS puede aprender una regla de exclusión. La página **"Lo que LANOPS ha aprendido de ti"**
enseña las reglas aprendidas (con cuántas ofertas esconden y un botón para quitarlas), los descartes (para recuperarlos)
y el perfil del alta (solo consulta: se cambia en el alta, Pieza 6).

Estado: **[08-oct-2026] `probado en real`** y publicado. Antes, `probado en simulación` (Postgres 16 local con `data/schema.sql`,
datos sintéticos, las 24 empresas, la persona demo y ofertas tipo Lanbide; nodos ejecutados tal cual con un simulador de n8n y
respuestas de Claude simuladas; 65 comprobaciones; páginas abiertas en Chromium).
En real (usuario sintético 1, ofertas de Lanbide, `claude-sonnet-5-5`): página `a=ver` (Test y Production URL); descarte por
"lo que se hace en el puesto" → la IA no ve regla clara y lo explica; descarte por "otro motivo" con texto ("no quiero trabajar de
dependiente en tienda") → regla `palabra = tienda` *propuesta por la IA*, con su porqué, que esconde 8 ofertas abiertas.
Cuadro del porqué con cualquier motivo (cambio posterior): solo en simulación, por decisión de Marcos. Quitar regla y recuperar: en simulación.

## Reglas
- **Motivo opcional.** Por defecto "solo quitarla": se guarda el descarte con `motivo = NULL` y no se aprende nada
  (mejor aprender menos que aprender mal por inercia). Motivos: `tarea` · `sector` · `empresa` · `salario` · `lejos` · `otro`.
- **El porqué en palabras del usuario** (campo `x`, ≤ 200 caracteres): el cuadro aparece al elegir **cualquier motivo** (se oculta con
  "solo quitarla"; CSS `:has`, sin JavaScript) y es **obligatorio con "otro motivo"** (script mínimo; si llega "otro" sin texto,
  `Code: entrada` no descarta y la página lo pide: `falta_porque`). Sin motivo, el texto se ignora. Va a la IA como dato (nunca como
  instrucción) cuando se le pregunta, y no va a ninguna tabla. Para que tampoco quede en n8n, el workflow tiene
  **Settings → Save successful production executions = Do not save** (las ejecuciones con error sí se guardan, para depurar,
  y ahí sí aparecería el texto). La API de Claude lo recibe para responder. Motivo de abrirlo a todos los motivos (08-oct, prueba real):
  con "lo que se hace en el puesto" y sin texto la IA casi nunca ve una regla clara; con el porqué del usuario, sí.
- **Reglas fijas (opción B), sin IA:**
  - `empresa` → excluye esa empresa al primer descarte.
  - `sector` → excluye el sector con `descartes_para_excluir_sector` (CONFIGURACION, 2) descartes por sector del mismo sector.
- **IA** (`Code: preparar IA` → `HTTP Request: Claude` → `Code: leer regla`), solo en descartes nuevos con motivo que las reglas fijas no cubren:
  `tarea`, `salario`, `lejos`, `otro` (siempre con texto); `sector` sin sector conocido; `empresa` de Lanbide (no publica la empresa, decisión 96).
  Claude lee la oferta, el motivo, el porqué del usuario si lo hay y el perfil de búsqueda (sin el CV) y propone **como mucho una** regla: `palabra` (aparece en la oferta),
  `municipio` (solo con "está lejos") o `contrato`, con una frase de porqué para el usuario. Modelo = el del evaluador IA activo.
  **`Code: leer regla` valida** antes de guardar (palabra genérica, que no está en la oferta, que choca con lo que busca el usuario,
  su municipio o contrato no negociable, clave no permitida, JSON roto o error de la API → no se aprende nada y el descarte queda guardado).
- Las reglas son exclusiones en `lanops.preferencias`: actúan en SQL al momento (`prefiltro.sql` y `lista.sql` de ENCAJE), **sin reevaluar**.
  Los pesos no se tocan (cambiarían la nota y obligarían a reevaluar: después del 11-oct).
- **Quitar** (`olvidar`) solo actúa sobre reglas aprendidas (con descartes que las respaldan); las del alta no se tocan desde aquí.
  Quitar una de empresa o sector deja esos descartes sin motivo (siguen descartados) para que no se reaprenda sola.
- **Recuperar** borra el descarte; la oferta vuelve sin gastar API (evaluación en caché). Si era el único apoyo de una regla, la regla se retira;
  si otra regla la sigue escondiendo, la página lo dice.
- "Aprendida" no es una columna (estructura congelada): se deduce de los descartes con las comparaciones de `prefiltro.sql`.
  Límite conocido: una exclusión del alta idéntica a una aprendida se ve como aprendida.

## Enlace
`…/webhook/descartar?u=<id>&t=<firma>&a=<acción>` con la **misma firma** que el enlace de ENCAJE (`encaje:<id>`, como CERTIFICADO).
`a=descartar&v=<vacante>[&m=<motivo>][&x=<porqué>]` · `a=recuperar&v=<vacante>` · `a=olvidar&k=empresa|sector|palabra|municipio|contrato&val=<valor>` · `a=ver`.
Sin `a`: con `v` descarta; sin `v`, enseña la página. Firma o parámetros malos → 403.

## Requisitos
- `configuracion.sql` ejecutado una vez (fila `descartes_para_excluir_sector = 2`).
- En ENCAJE: `lista.sql` [08-oct] aplica también las exclusiones y `code-html.js` [08-oct] lleva el formulario y el enlace a esta página.
- Variable `ENCAJE_SECRET` y credenciales `Postgres LANOPS (marcos)` y `Anthropic LANOPS` (ya existen).
- Coste: una llamada corta por descarte con motivo (sin caché: el bloque fijo no llega al mínimo cacheable). Medir en la prueba real.

| # | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Webhook /descartar` | — | GET · Path `descartar` · Respond: Using 'Respond to Webhook' Node |
| 2 | `Code: firma` | `../LANOPS-ENCAJE/code-firma.js` | Igual que en ENCAJE |
| 3 | `Code: entrada` | `code-entrada.js` | Run Once for All Items |
| 4 | `IF firma válida` | — | `{{ $json.valido }}` is true · false → `Respond 403` (Text `Enlace no válido.`, 403) |
| 5 | `Postgres: aplicar` | `aplicar.sql` | Execute Once ON · Always Output Data ON · `{{ [ JSON.stringify($('Code: entrada').first().json) ] }}` |
| 6 | `Code: preparar IA` | `code-preparar.js` | Run Once for All Items |
| 7 | `IF ¿preguntar a la IA?` | — | `{{ $json.pedir }}` is true → 8 · false → 10 |
| 8 | `HTTP Request: Claude` | — | Copia del de ENCAJE (POST `https://api.anthropic.com/v1/messages`, credencial `Anthropic LANOPS`, `anthropic-version: 2023-06-01`, Body `{{ $json.cuerpo }}`) · Timeout 60000 · On Error: Continue |
| 9 | `Code: leer regla` | `code-leer.js` | Run Once for All Items |
| 10 | `Postgres: aprender` | `aprender.sql` | Execute Once ON · Always Output Data ON · `{{ [ JSON.stringify({ ...$('Postgres: aplicar').first().json, usuario: $('Code: entrada').first().json.usuario, regla: $json.regla, porque: $json.porque }) ] }}` · entra desde 7 (false) y 9 |
| 11 | `Postgres: aprendido` | `aprendido.sql` | Igual · `{{ [ $('Code: entrada').first().json.usuario, $('Code: entrada').first().json.vacante ] }}` |
| 12 | `Code: HTML` | `code-html.js` | Run Once for All Items. Usa `$('Code: entrada')`, `$('Postgres: aplicar')`, `$('Postgres: aprender')` y `$('Code: leer regla')`: **nombres exactos** |
| 13 | `Respond to Webhook` | — | Text `{{ $json.html }}` · `Content-Type: text/html; charset=utf-8` · `Cache-Control: no-store` · Response Code `{{ $json.status }}` |

`workflow.json` trae los nodos ya configurados: se importa en n8n. `comprobar.sql`: consulta read-only de descartes y reglas de un usuario.

Probado en simulación (8-oct, 63 comprobaciones; texto libre: "otro" sin texto (o solo espacios) no descarta ni llama a la IA y lo pide, texto con otro motivo se ignora, texto limpio y recortado a 200, intento de dar órdenes a la IA parado por la validación, el texto no llega a la base de datos): 403 con firma de otro usuario, sin firma, `v` no numérico, acción y clave no permitidas;
sin motivo (no aprende ni llama a la IA; recargar no duplica); empresa y sector (sin IA; quitar el sector no se reaprende; una exclusión
del alta no se puede quitar; recuperar retira la de empresa); IA con ofertas tipo Lanbide (petición con oferta, motivo y perfil, sin CV;
palabra aprendida, la otra oferta parecida sale de la lista; recargar no vuelve a llamar); validación (palabra genérica o ausente,
municipio sin "lejos" o no negociable, contrato distinto, clave no permitida, JSON roto, error de la API → sin regla); sin regla la página
dice por qué; "a comisión" → `a comision`; municipio con dos apoyos (recuperar uno avisa de que sigue escondida); quitar reglas de la IA
(las ofertas vuelven; la exclusión del alta sigue); Lanbide con empresa o sector → IA; recuperar el único apoyo retira la regla;
vacante inexistente; valor con HTML escapado.
