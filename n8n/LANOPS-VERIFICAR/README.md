# LANOPS-VERIFICAR (n8n)

Verificación del certificado (Pieza 5, dueño Marcos). La empresa escanea el QR → página estática
`https://lanopsdmm.github.io/lanops/verificar/?c=<codigo>` (Pieza 6, Javi) → su JavaScript llama a este webhook
→ n8n recalcula la firma con `CERT_SECRET`, mira estado y caducidad, suma 1 a `veces_verificado` y responde JSON.
Sin login. Así el QR impreso no depende de la URL de Railway (decisión 8).

Estado: **[07-oct-2026] `probado en simulación`** (mismo banco de pruebas que `LANOPS-CERTIFICADO`). Falta montarlo en n8n.

| # | Nodo n8n | Archivo | Configuración |
|---|---|---|---|
| 1 | `Webhook /verificar` | — | GET · Path `verificar` · Respond: Using 'Respond to Webhook' Node · Options → Allowed Origins (CORS) `*` |
| 2 | `Postgres: buscar` | `buscar.sql` | Execute Query · Execute Once ON · **Always Output Data ON** · Query Parameters (ver cabecera) |
| 3 | `Code: comprobar` | `code-comprobar.js` | Run Once for All Items. Usa `$('Webhook /verificar')`: **el nombre del nodo 1 debe ser exacto** |
| 4 | `Postgres: contar` | `contar.sql` | Execute Query · Execute Once ON · **Always Output Data ON** · Query Parameters (ver cabecera) |
| 5 | `Respond to Webhook` | — | Respond With JSON · Response Body `{{ $('Code: comprobar').first().json.respuesta }}` · Header `Cache-Control: no-store` |

CORS: el certificado no tiene nada secreto para quien ya tiene el código (cualquiera con el código puede abrir la URL
directamente), así que se permite cualquier origen (`*`); también sirve para que Javi pruebe la página en local.

## Contrato para `verificar/index.html` (Pieza 6)

`GET <URL de producción de n8n>/webhook/verificar?c=<codigo>` → siempre **200** y JSON (decisiones 97–98):

```json
{
  "valido": true,
  "estado": "vigente",
  "codigo": "61875398-a4e6-42e5-83ea-3362a9e0266c",
  "titular": "Carlos Rojas",
  "titular_verificado": true,
  "entidad": "EKINN Harrera",
  "puesto": "Ingeniero/a de procesos",
  "empresa": "Empresa de Prueba S. Coop.",
  "ubicacion": "Arrasate",
  "url_oferta": "https://…",
  "porcentaje": 86,
  "global": 4.3,
  "banda": "Alta",
  "dimensiones": { "d1_match_cv": 5, "d2_north_star": 4, "d3_compensacion": 4, "d4_cultura": 4, "d5_red_flags": 5 },
  "fecha_evaluacion": "2026-10-07",
  "fecha_emision": "2026-10-07",
  "fecha_caducidad": "2026-11-06",
  "version_rubrica": "oferta-2026-09",
  "modelo": "claude-sonnet-5-5",
  "veces_verificado": 1
}
```

- `valido` es `true` solo si `estado` = `vigente`.
- `estado`: `vigente` · `caducado` · `revocado` (con todos los datos) · `no_encontrado` · `firma_no_valida`
  (estos dos solo traen `valido`, `estado` y `codigo`: no se enseña nada de un certificado que no cuadra).
- `entidad` es `null` si el titular no está verificado (entrada abierta, decisión 25).
- `empresa` de Lanbide = `"Empresa no publicada · oferta gestionada por Lanbide"` (decisión 96).
- `porcentaje` = `global` × 20 redondeado (decisión 26). Mostrar siempre junto a `global`/5 y las dimensiones.
- Nombres de las dimensiones para la página: Encaje con el CV · Alineación con lo que busca · Compensación ·
  Cultura y condiciones · Alertas (5 = ninguna).
- Fechas en `AAAA-MM-DD`. `fetch` sin cabeceras propias (petición simple: sin *preflight*).

Probado en simulación (7-oct): vigente (datos y d1–d5 correctos, cuenta 1 y 2); código inexistente, basura e
inyección → `no_encontrado`; `global` o firma manipulados en la base → `firma_no_valida` sin datos y sin contar;
revocado → `valido: false` con datos y sigue revocado; fecha pasada → `caducado` y se guarda en la base.
