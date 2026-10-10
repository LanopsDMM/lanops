# LANOPS-AGENTE (n8n)

Agente de webs (Pieza 6, dueño Javi). Lee la página de empleo de cada empresa de `lanops.empresas` (cargadas desde
`data/empresas.csv`) y guarda sus ofertas en VACANTES con `fuente='agente'`. Es lo que hace real "leemos a quien no publica".

Estado: **[10-oct-2026] `construido`**. Las lógicas de robots.txt, HTML → texto, JSON-LD y lectura están probadas con datos de prueba en Node. El SQL está probado en un Postgres 16 local: alta, segunda pasada, cierre a los 14 días, fallos seguidos y alerta. No está probado en n8n.

## Flujo

| # | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Ejecutar a mano` → `Code: solo prueba` | `code-prueba.js` | para probar: solo 9 empresas (las 8 con ofertas en texto + Elkar) |
| 2 | `Cada lunes 07:00` → `Code: todas` | `code-todas.js` | Schedule Trigger semanal; lista vacía = todas |
| 3 | `Postgres: empresas` | `empresas.sql` | activas con `url_empleo`, sin `tipo_lectura='ninguna'` · Query Parameters `{{ [ JSON.stringify($json.solo) ] }}` |
| 4 | `HTTP Request: robots.txt` | — | GET `{{ $json.robots_url }}` · User-Agent `LANOPS-bot/0.1 (+https://github.com/LanopsDMM/lanops)` · Full Response, Never Error, formato texto · Timeout 15000 · 1 cada 0,5 s · On Error: Continue |
| 5 | `Code: robots.txt` | `code-permitido.js` | deja pasar solo las empresas que robots.txt permite (grupo `LANOPS-bot` o `*`; 4xx = permitido; 5xx/error = no) |
| 6 | `HTTP Request: página de empleo` | — | GET `{{ $json.url_empleo }}` · mismas opciones · Timeout 20000 · 1 cada 2 s |
| 7 | `Code: texto y petición` | `code-texto.js` | JSON-LD `JobPosting` si lo hay; si no, HTML → texto (≤ 15.000 caracteres, con los enlaces) → petición a Claude |
| 8 | `HTTP Request: Claude` | — | como en ENCAJE (credencial Anthropic, `anthropic-version`, Timeout 120000) · On Error: Continue |
| 9 | `Code: leer` | `code-leer.js` | vacantes (≤ 30 por empresa, enlaces absolutos) + "Candidatura espontánea" si la empresa solo recibe CV + resultado por empresa + `resumen` legible |
| 10 | `Postgres: guardar` | `guardar.sql` | upsert de VACANTES; `ultima_lectura` y `fallos_seguidos` de EMPRESAS; cierre de las no vistas en `cierre_agente_dias` (14); devuelve nuevas, vistas otra vez, cerradas y `alertas` (≥ 2 fallos seguidos) |

## Reglas

- **Sin portales comerciales.** Solo las URLs de la propia empresa o de su ATS (`data/empresas.csv`). Se respeta robots.txt, y no se visita lo que bloquea.
- `hash` = md5(`agente|empresa|puesto|url`): la misma oferta se reconoce cada semana aunque cambie la descripción.
- **Una empresa cuenta como leída** si su página da al menos una oferta o una candidatura espontánea; si no, `fallos_seguidos + 1`. Las de ATS con JavaScript (TalentClue, SuccessFactors, Workday) acabarán con fallos: es lo esperado hasta que haya lector de ATS.
- Solo se cierran ofertas de empresas que se han leído bien esta vez. Así un fallo de red no cierra nada.
- **Caso "envía tu CV a rrhh@":** si la página no tiene ofertas pero invita a mandar el CV → vacante `puesto='Candidatura espontánea'` con cómo enviarlo en `requisitos`.
- No hay correo de alerta (no hay remitente, decisión 108): las alertas salen en la salida de `Postgres: guardar` y en `resumen` de `Code: leer`.
