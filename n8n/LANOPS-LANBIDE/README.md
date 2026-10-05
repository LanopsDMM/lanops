# LANOPS-LANBIDE (n8n)

Conector diario de Lanbide Open Data → `lanops.vacantes` (Pieza 5, dueño Marcos).
Fuente: Lanbide / Open Data Euskadi (CC BY). Solo trae las ofertas gestionadas por Lanbide (origen "Lanbide" en su web); no las de Unión Europea, empleo público ni otros orígenes.

| Orden | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Schedule Trigger (06:00)` | — | Every day, 06:00, zona Europe/Madrid |
| 2 | `HTTP Request (JSON)` | — | GET `https://apps.lanbide.euskadi.net/apps/OF_OFERTAS_ODE_JSON` · Options → Response → Response Format **File**, Put Output in Field `data` |
| 3 | `Code: filtrar` | `code-filtrar.js` | Run Once for All Items · JavaScript |
| 4 | `Postgres: upsert vacantes` | `upsert.sql` | Execute Query · Query Parameters `{{ [ JSON.stringify($input.all().map(i => i.json)) ] }}` · Settings → Execute Once ON |
| 5 | `Postgres: cerrar desaparecidas` | `cierre.sql` | Execute Query · Execute Once ON · activo (ítem 27 resuelto el 5-oct) |

Comprobación read-only: `comprobar.sql`.
Probado en simulación el 5-oct-2026 (JSON real del día + Postgres 16 local): 261 nuevas, 261 actualizadas en la 2.ª pasada, cierre correcto.
