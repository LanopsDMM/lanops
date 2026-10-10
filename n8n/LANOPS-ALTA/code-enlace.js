// n8n · workflow LANOPS-ALTA · nodo "Code: enlace"
// Modo: Run Once for All Items · JavaScript
// Enlace firmado a la lista de ENCAJE del usuario recién dado de alta (decisiones 63, 90 y 120 opción a):
// firma = HMAC-SHA256(ENCAJE_SECRET, 'encaje:' + id), el mismo cálculo que LANOPS-ENCAJE/code-firma.js.
// El secreto se lee de Railway con $env y no aparece en la salida. Se enseña en la pantalla final del alta.
const BASE = 'https://n8n-production-3c20b.up.railway.app/webhook/encaje';

function sha256(bytes) {
  const K = [0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2];
  const H = [0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19];
  const l = bytes.length, n = ((l + 9 + 63) >> 6) << 6, m = new Uint8Array(n);
  m.set(bytes); m[l] = 0x80;
  const bits = l * 8;
  m[n - 4] = (bits >>> 24) & 255; m[n - 3] = (bits >>> 16) & 255; m[n - 2] = (bits >>> 8) & 255; m[n - 1] = bits & 255;
  m[n - 5] = Math.floor(bits / 2 ** 32) & 255;
  const w = new Uint32Array(64), r = (x, s) => (x >>> s) | (x << (32 - s));
  for (let i = 0; i < n; i += 64) {
    for (let t = 0; t < 16; t++) w[t] = (m[i+4*t] << 24) | (m[i+4*t+1] << 16) | (m[i+4*t+2] << 8) | m[i+4*t+3];
    for (let t = 16; t < 64; t++) {
      const s0 = r(w[t-15], 7) ^ r(w[t-15], 18) ^ (w[t-15] >>> 3);
      const s1 = r(w[t-2], 17) ^ r(w[t-2], 19) ^ (w[t-2] >>> 10);
      w[t] = (w[t-16] + s0 + w[t-7] + s1) | 0;
    }
    let [a, b, c, d, e, f, g, h] = H;
    for (let t = 0; t < 64; t++) {
      const t1 = (h + (r(e, 6) ^ r(e, 11) ^ r(e, 25)) + ((e & f) ^ (~e & g)) + K[t] + w[t]) | 0;
      const t2 = ((r(a, 2) ^ r(a, 13) ^ r(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) | 0;
      h = g; g = f; f = e; e = (d + t1) | 0; d = c; c = b; b = a; a = (t1 + t2) | 0;
    }
    H[0] = (H[0] + a) | 0; H[1] = (H[1] + b) | 0; H[2] = (H[2] + c) | 0; H[3] = (H[3] + d) | 0;
    H[4] = (H[4] + e) | 0; H[5] = (H[5] + f) | 0; H[6] = (H[6] + g) | 0; H[7] = (H[7] + h) | 0;
  }
  const out = new Uint8Array(32);
  H.forEach((v, i) => { out[4*i] = v >>> 24; out[4*i+1] = (v >>> 16) & 255; out[4*i+2] = (v >>> 8) & 255; out[4*i+3] = v & 255; });
  return out;
}
const utf8 = (s) => new TextEncoder().encode(s);
function hmacHex(secreto, mensaje) {
  let k = utf8(secreto);
  if (k.length > 64) k = sha256(k);
  const ki = new Uint8Array(64), ko = new Uint8Array(64);
  for (let i = 0; i < 64; i++) { ki[i] = (k[i] || 0) ^ 0x36; ko[i] = (k[i] || 0) ^ 0x5c; }
  const m = utf8(mensaje), interior = new Uint8Array(64 + m.length);
  interior.set(ki); interior.set(m, 64);
  const ih = sha256(interior), exterior = new Uint8Array(96);
  exterior.set(ko); exterior.set(ih, 64);
  return Array.from(sha256(exterior), (x) => x.toString(16).padStart(2, '0')).join('');
}

const g = $input.first().json;                       // salida de "Postgres: guardar"
const usuario = parseInt(g.usuario, 10);
if (!usuario) throw new Error('ALTA: no se ha guardado el usuario');
const secreto = $env.ENCAJE_SECRET;
if (!secreto) throw new Error('Falta la variable ENCAJE_SECRET en el servicio n8n');
const enlace = `${BASE}?u=${usuario}&t=${hmacHex(secreto, 'encaje:' + usuario)}`;
const esc = (s) => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const nombre = String($('Code: preparar').first().json.datos.nombre || '').split(' ')[0];
const huecos = $('Code: leer 1').first().json.huecos || [];

const consejos = huecos.length ? `<h2>Para afinar tu encaje</h2>
<p>Tu CV no responde a estas preguntas. Si las contestas en tu CV y vuelves a hacer el alta con el mismo email, LANOPS te evaluará mejor:</p>
<ul>${huecos.map(h => `<li>${esc(h)}</li>`).join('')}</ul>` : '';

const html = `<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex">
<title>Tu perfil · LANOPS</title>
<link rel="stylesheet" href="https://lanopsdmm.github.io/lanops/styles.css"></head><body>
<header><p class="marca">LANOPS</p></header>
<main>
<h1>${g.ya_existia ? 'Perfil actualizado' : 'Ya estás en LANOPS'}${nombre ? ', ' + esc(nombre) : ''}</h1>
<p>Este es tu enlace personal a las ofertas que encajan contigo. <strong>Guárdalo en favoritos</strong>: no te lo enviamos por correo y es la única forma de volver a tu lista.</p>
<p><a class="boton" href="${esc(enlace)}">Ver mis ofertas</a></p>
<p class="codigo">${esc(enlace)}</p>
<p>La primera vez tarda un par de minutos: LANOPS evalúa para ti las ofertas abiertas. Desde la lista puedes pedir tu certificado.</p>
${g.entidad_encontrada ? '<p class="aviso">Tu email corresponde a una entidad colaboradora: tu verificación queda pendiente.</p>' : ''}
${consejos}
<p>Para cambiar tu perfil, vuelve a hacer el alta con el mismo email.</p>
</main>
<footer><p><a href="https://lanopsdmm.github.io/lanops/">LANOPS</a> · La IA evalúa; tú decides.</p></footer>
</body></html>`;

return [{ json: { usuario, enlace, html } }];
