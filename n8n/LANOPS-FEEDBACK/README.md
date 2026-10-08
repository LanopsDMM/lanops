# LANOPS-FEEDBACK (n8n)

Lo que LANOPS aprende de los descartes (Pieza 5, dueño Marcos; opción B del 08-oct-2026).
En cada tarjeta de la lista de ENCAJE hay un formulario **"No me interesa por … · Descartar"**; la oferta sale
de la lista y, según el motivo, LANOPS aprende una exclusión. La página **"Lo que LANOPS ha aprendido de ti"**
enseña lo aprendido, los descartes y el perfil de búsqueda, y deja **deshacer** (dejar de excluir) y **recuperar** ofertas.

Estado: **[08-oct-2026] `probado en simulación`** (Postgres 16 local con `data/schema.sql`, los datos sintéticos,
las 24 empresas y la persona demo; nodos Code y Postgres ejecutados tal cual con un simulador de n8n; 37 comprobaciones;
páginas abiertas en Chromium). Falta montarlo en n8n.

## Reglas (opción B)
- Motivos: `tarea` (lo que se hace en el puesto) · `sector` · `empresa` · `salario` · `lejos` · `otro`. Todos se guardan en `lanops.feedback`
  (`veredicto = 'descartada'`); la oferta deja de salir (ya lo hacían `prefiltro.sql` y `lista.sql`).
- **`empresa`** → exclusión de esa empresa en `lanops.preferencias` al primer descarte. **Lanbide no** (no publica la empresa, decisión 96): se guarda el motivo y se explica.
- **`sector`** → exclusión del sector cuando hay `descartes_para_excluir_sector` (CONFIGURACION, 2) descartes por sector del mismo sector. Sin sector conocido, no aprende.
- `tarea`, `salario`, `lejos`, `otro` → solo se guardan.
- **Deshacer** (`olvidar`): borra la exclusión aprendida y deja sin motivo los descartes que la enseñaron (siguen descartados, pero no la vuelven a enseñar).
  Solo actúa sobre exclusiones con descartes detrás: las del alta no se tocan desde aquí.
- **Recuperar**: borra el descarte; la oferta vuelve (sin gastar API: la evaluación sigue en caché). Si era el apoyo de una exclusión aprendida, la exclusión se retira cuando queda por debajo del umbral.
- "Aprendida" no es una columna (estructura congelada): se deduce de los descartes. Límite conocido: si el usuario puso en su alta la misma exclusión que luego aprende, se ven como una sola.
- Sin JavaScript en la página; formularios GET al mismo webhook (relativos: valen en la Test URL y en la Production URL).
- La IA no decide estas reglas: puntúa las ofertas (ENCAJE). Lo aprendido son reglas a la vista que el usuario deshace.

## Enlace
`…/webhook/descartar?u=<id>&t=<firma>&a=<acción>` con la **misma firma** que el enlace de ENCAJE (`encaje:<id>`, como CERTIFICADO).
`a=descartar&v=<vacante>&m=<motivo>` · `a=recuperar&v=<vacante>` · `a=olvidar&k=empresa|sector&val=<valor>` · `a=ver`.
Sin `a`: con `v` descarta; sin `v`, enseña la página. Firma o parámetros malos → 403.

## Requisitos
- `configuracion.sql` ejecutado una vez (fila `descartes_para_excluir_sector = 2`).
- En ENCAJE: `lista.sql` [08-oct] también aplica las exclusiones (una exclusión aprendida oculta lo ya evaluado) y
  `code-html.js` [08-oct] lleva el formulario de descarte y el enlace a "Lo que LANOPS ha aprendido de ti".
- Variable `ENCAJE_SECRET` (ya existe).

| # | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Webhook /descartar` | — | GET · Path `descartar` · Respond: Using 'Respond to Webhook' Node |
| 2 | `Code: firma` | `../LANOPS-ENCAJE/code-firma.js` | Igual que en ENCAJE (Run Once for All Items) |
| 3 | `Code: entrada` | `code-entrada.js` | Run Once for All Items |
| 4 | `IF firma válida` | — | `{{ $json.valido }}` is true · rama false → `Respond 403` |
| 4b | `Respond 403` | — | Respond With Text · `Enlace no válido.` · Response Code 403 |
| 5 | `Postgres: aplicar` | `aplicar.sql` | Execute Query · Execute Once ON · Always Output Data ON · `{{ [ JSON.stringify($('Code: entrada').first().json) ] }}` |
| 6 | `Postgres: aprender` | `aprender.sql` | Igual · `{{ [ JSON.stringify({ ...$('Postgres: aplicar').first().json, usuario: $('Code: entrada').first().json.usuario }) ] }}` |
| 7 | `Postgres: aprendido` | `aprendido.sql` | Igual · `{{ [ $('Code: entrada').first().json.usuario ] }}` |
| 8 | `Code: HTML` | `code-html.js` | Run Once for All Items. Usa `$('Code: entrada')`, `$('Postgres: aplicar')`, `$('Postgres: aprender')`: **nombres exactos** |
| 9 | `Respond to Webhook` | — | Respond With Text · `{{ $json.html }}` · Headers `Content-Type: text/html; charset=utf-8` y `Cache-Control: no-store` · Response Code `{{ $json.status }}` |

`workflow.json` trae los 10 nodos ya configurados (credencial `Postgres LANOPS (marcos)`): se importa en n8n.
`comprobar.sql`: consulta read-only de descartes y exclusiones de un usuario, para verificar una prueba.

Probado en simulación (8-oct): firma de otro usuario, sin firma, `v` no numérico, acción y clave no permitidas → 403 sin escribir nada;
descartar por tarea (no aprende; recargar no duplica); 1.er descarte por sector (no aprende, avisa de cuántos faltan);
por empresa (aprende al momento; la otra oferta ya evaluada de esa empresa sale de la lista); 2.º por sector con
`I+D`/`i+d` (aprende); deshacer el sector (no se reaprende); deshacer una exclusión del alta (no se toca); recuperar
(retira la exclusión sin apoyo y la oferta vuelve); recuperar con otro apoyo (sigue oculta y lo dice); Lanbide por empresa
(no excluye al comodín, lo explica); vacante inexistente; valor con HTML escapado.
