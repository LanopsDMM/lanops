# `data/empresas.csv` — empresas de Gipuzkoa con página de empleo (Pieza 8 → Pieza 6)

24 empresas reales de Gipuzkoa (anillo 1) con su página de empleo propia, para el agente de webs de la Pieza 6
(`LANOPS-AGENTE`) y el `portals.yml` del fork. Mismas columnas que `EMPRESAS` (sin `id`, `ultima_lectura`,
`fallos_seguidos`, `activa`). Separador `;`, UTF-8.

**Cargar en Postgres:** pegar `data/cargar-empresas.sql` en `LANOPS · SQL a mano`. Inserta las que no existan
(Ceit ya está, id 62) y se puede repetir sin duplicar. Resultado esperado la primera vez: `insertadas 23 · total_empresas 25`.

## Cómo se comprobó (07-oct-2026, Marcos con Claude)
Cada `url_empleo` se abrió con un lector web (no hubo acceso HTTP directo) y se anotó qué se veía. `tipo_lectura` sigue
el modelo de datos: `html` = la lista de ofertas está en la página · `ats` = la gestiona una plataforma externa
(TalentClue, SAP SuccessFactors, Teamtailor, Workday) · `manual` = solo formulario o buzón de CV, sin lista ·
`ninguna` = no se pudo comprobar la URL.

| Empresa | Qué se vio el 07-oct | Plataforma |
|---|---|---|
| Vicomtech | 7 ofertas en la página (p. ej. "Desarrollador/a Full Stack", Donostia) | propia (html) |
| CIC nanoGUNE | 3 ofertas ("Pre-doctoral Researcher in Quantum Computing"…) | propia (html) |
| Ceit | ofertas en TalentClue (la de la demo del certificado). `ceit.es/es/…` está bloqueada por robots.txt; la versión `/en/` se lee | TalentClue |
| Tecnalia | página "ofertas de empleo" que enlaza a TalentClue; no se ve la lista en texto | TalentClue |
| Ikerlan | su web no deja leer robots.txt; **URL de empleo no comprobada**. Sus ofertas salen en el portal de MONDRAGON (fila de abajo) | — |
| Orona | portal de empleo propio; la lista no aparece en texto | SAP SuccessFactors |
| CAF | portal `jobs.caf.net` (grupo CAF, Solaris, Euromaint); la lista no aparece en texto | SAP SuccessFactors |
| Irizar | solo formulario de CV en "Contacto → Trabaja con nosotros" | — |
| Fagor Arrasate | tabla de ofertas cargada por JavaScript | TalentClue |
| Fagor Ederlan | "ofertas disponibles" sin lista en texto | TalentClue |
| Danobatgroup | "procesos de selección abiertos" sin lista; remite a boletín y LinkedIn | — |
| Orkli | solo portal de envío de CV | propio |
| Ingeteam Indar Machines | 5 ofertas, todas en **Beasain** ("Application Engineer", "Técnico/a de montaje"…) | Teamtailor |
| Copreci | 4 perfiles buscados y envío de CV | TalentClue |
| Ikusi | portal Workday; la lista no aparece en texto | Workday |
| LKS Next | página de ofertas sin lista en texto | TalentClue |
| Laboral Kutxa | portal por áreas y provincias (Gipuzkoa…) | SAP SuccessFactors |
| Mondragon Unibertsitatea | página "ofertas" que remite a cada facultad | propia |
| MONDRAGON Corporación | **169 ofertas** de las cooperativas, una página por oferta (LKS Next, Ikerlan, Ondoan…) | propia (html) |
| Gureak | 5 ofertas (Gureak Itinerary, p. ej. "Auxiliar de producción", Irun) + formulario | propia (html) |
| Matia Fundazioa | 9 ofertas ("Enfermero/a Hospital Matia"…) | Teamtailor |
| Ausolan | 14 páginas de ofertas (p. ej. Donostia) | propia (html) |
| BM Supermercados (Grupo Uvesco) | 9 ofertas, varias en las oficinas de Irun | Teamtailor |
| Elkar | solo formulario de CV (servicios generales, editorial, distribución, tiendas) | — |

## Para el agente de webs (Javi)
- **Empezar por las 8 que muestran las ofertas en texto plano**: MONDRAGON Corporación, Vicomtech, CIC nanoGUNE,
  Ausolan, Gureak, Matia Fundazioa, Ingeteam Indar Machines y BM Supermercados. Con ellas el criterio "probado en real
  contra 5 empresas" de la Pieza 6 se cumple.
- Las de TalentClue, SuccessFactors y Workday cargan la lista con JavaScript: el paso "HTML → texto → Claude" no verá
  ofertas. Quedan con `fallos_seguidos` hasta que se lea su ATS (pendiente, como el escáner de ATS de la Pieza 5).
- Las `manual` no publican lista: sirven para el caso "Candidatura espontánea" de la Pieza 6.
- Respetar robots.txt (ya está en el diseño del agente): Ceit en castellano lo bloquea.
- Sin portales comerciales (principio de contexto.md): todas las URL son de la propia empresa o de su ATS.

## No incluidas (y por qué)
Multiverse Computing (sin enlace de empleo en su web el 07-oct), Basque Culinary Center y DIPC (certificado SSL no
verificable desde el lector), Soraluce y Egile (sin enlace de empleo visible), ULMA (robots.txt ilegible),
Sidenor (sede en Bizkaia), Goizper (redirige a otro dominio).
