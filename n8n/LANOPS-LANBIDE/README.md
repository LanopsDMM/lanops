# LANOPS-LANBIDE (n8n)

Conector diario de Lanbide Open Data → `lanops.vacantes` (Pieza 5, dueño Marcos).
Fuente: Lanbide / Open Data Euskadi (CC BY). Solo trae las ofertas gestionadas por Lanbide (origen "Lanbide" en su web); no las de Unión Europea, empleo público ni otros orígenes.

| Orden | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Schedule Trigger (06:00)` | — | Every day, 06:00, zona Europe/Madrid |
| 2 | `HTTP Request (JSON)` | — | GET `https://web.lanbide.eus/apps/OF_OFERTAS_ODE_JSON` · Options → Response → Response Format **File**, Put Output in Field `data` · Options → **Ignore SSL Issues** ON · Options → **Timeout** `30000` |
| 3 | `Code: filtrar` | `code-filtrar.js` | Run Once for All Items · JavaScript |
| 4 | `Postgres: upsert vacantes` | `upsert.sql` | Execute Query · Query Parameters (Expression) `{{ [ JSON.stringify($input.all().map(i => i.json)) ] }}` · Settings → Execute Once ON |
| 5 | `Postgres: cerrar desaparecidas` | `cierre.sql` | Execute Query · Execute Once ON · activo (ítem 27 resuelto el 5-oct) |

Credencial de los nodos 4 y 5: `Postgres LANOPS (marcos)` (host privado `postgres.railway.internal:5432`, base `railway`, SSL Disable).
Requiere el esquema creado (`data/schema.sql`) y la empresa comodín (`data/semilla-lanbide.sql`).

## Por qué `web.lanbide.eus` y no `apps.lanbide.euskadi.net` (6-oct)
- `apps.lanbide.euskadi.net` (la URL del catálogo de Open Data) **no responde** desde Railway ni desde otros servidores en la nube: la conexión se queda colgada. Desde un navegador en España sí responde.
- `web.lanbide.eus` sirve el mismo archivo y sí responde desde Railway. Lo envía como `application/jsonp`; `code-filtrar.js` acepta UTF-8 o ISO-8859-1 y quita un posible envoltorio `callback(...)`.
- Su certificado lo firma Izenpe (autoridad del Gobierno Vasco), que n8n no trae en su lista → error *self-signed certificate in certificate chain*. Se usa **Ignore SSL Issues** solo en este nodo: es una descarga de datos públicos sin credenciales. Alternativa limpia (pendiente): añadir la raíz de Izenpe con `NODE_EXTRA_CA_CERTS` en el servicio n8n de Railway.
- `url_origen` de cada vacante apunta ya a la ficha en `web.lanbide.eus`.

Comprobación read-only: `comprobar.sql`.
Probado en simulación el 5-oct-2026 (JSON real del día + Postgres 16 local): 261 nuevas, 261 actualizadas en la 2.ª pasada, cierre correcto.
**Probado en n8n contra Railway el 6-oct-2026:** 1.ª ejecución 256 nuevas; 2.ª ejecución 255 actualizadas (`nueva = false`), una retirada de Lanbide entre ambas; cierre sin filas (correcto el mismo día). `comprobar.sql` → `lanbide | abierta | 256`. Workflow publicado (diario 06:00, Europe/Madrid); falta ver la primera ejecución programada.
