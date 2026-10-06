# Genera n8n/LANOPS-ENCAJE/cargar-evaluador.sql: carga en lanops.evaluadores (id 1, IA)
# el modelo y el prompt = motor/modes/_shared.md + motor/modes/oferta.md + envoltorio.md (decisión 61).
# Uso: python3 -I generar_evaluador.py <carpeta motor/modes> <envoltorio.md> <modelo> <salida .sql>
# Los "$" del texto se escriben como @@DOLAR@@ y Postgres los repone con chr(36): así n8n no los
# confunde con parámetros ($1, $90...) de la consulta.
import hashlib, os, sys

modes, envoltorio, modelo, out = sys.argv[1:5]
partes = [open(os.path.join(modes, '_shared.md'), encoding='utf-8').read(),
          open(os.path.join(modes, 'oferta.md'), encoding='utf-8').read(),
          open(envoltorio, encoding='utf-8').read()]
prompt = '\n\n'.join(p.strip('\n') for p in partes) + '\n'
MARCA = '@@DOLAR@@'
assert MARCA not in prompt and '\x00' not in prompt
lit = "'" + prompt.replace("'", "''").replace('$', MARCA) + "'"
huella = hashlib.md5(prompt.encode('utf-8')).hexdigest()
sql = f"""-- LANOPS-ENCAJE · evaluador IA (id 1): modelo y prompt (decisión 61, ítem 29).
-- Generado con n8n/LANOPS-ENCAJE/generar_evaluador.py. Se ejecuta entero en LANOPS · SQL a mano.
-- Esperado al final: modelo = {modelo} · caracteres = {len(prompt)} · huella = {huella}
UPDATE lanops.evaluadores
SET modelo = '{modelo}',
    prompt = replace({lit}, '{MARCA}', chr(36))
WHERE id = 1 AND tipo = 'ia';
SELECT id, nombre, activo, modelo, length(prompt) AS caracteres, md5(prompt) AS huella
FROM lanops.evaluadores WHERE id = 1;
"""
open(out, 'w', encoding='utf-8').write(sql)
print('caracteres', len(prompt), 'huella', huella, 'bytes sql', len(sql.encode('utf-8')))
