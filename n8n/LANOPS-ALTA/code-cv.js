// n8n · workflow LANOPS-ALTA · nodo "Code: CV"
// Modo: Run Once for All Items · JavaScript
// El formulario de alta (lanops/alta/index.html) envía multipart/form-data al nodo "Webhook /alta".
// Aquí se busca el archivo que llegue (sea cual sea su nombre) y se renombra a "cv" para Extract from File.
const item = $input.first();
const claves = Object.keys(item.binary || {});
if (!claves.length) throw new Error('ALTA: no ha llegado ningún archivo. Sube tu CV en PDF.');
return [{ json: item.json, binary: { cv: item.binary[claves[0]] } }];
