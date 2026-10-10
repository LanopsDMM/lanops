// n8n · workflow LANOPS-PEGAR-OFERTA · nodo "Code: página de error"
// Modo: Run Once for All Items · JavaScript
// Rama "false" de "IF entrada válida": enlace personal no válido o texto demasiado corto.
const m = $input.first().json.motivo;
const msg = m === 'texto'
  ? 'El texto de la oferta es demasiado corto. Pega la oferta completa (puesto, requisitos, condiciones).'
  : 'No reconocemos tu enlace personal. Copia el enlace completo de "Ver mis ofertas" que te dimos al crear tu perfil.';
const html = `<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex">
<title>No se ha podido evaluar · LANOPS</title>
<link rel="stylesheet" href="https://lanopsdmm.github.io/lanops/styles.css"></head><body>
<header><p class="marca">LANOPS</p></header>
<main><h1>No se ha podido evaluar la oferta</h1>
<p class="aviso">${msg}</p>
<p><a href="https://lanopsdmm.github.io/lanops/pegar-oferta/">Volver a intentarlo</a> · <a href="https://lanopsdmm.github.io/lanops/alta/">Crear mi perfil</a></p>
</main></body></html>`;
return [{ json: { html } }];
