-- LANOPS · datos de DEMO para el certificado (Pieza 5, 07-oct-2026)
-- Se pega en n8n → workflow "LANOPS · SQL a mano" (credencial Postgres LANOPS (marcos)) y se ejecuta una vez.
-- Crea:
--   · una PERSONA DEMO ficticia (Irati Goenaga), marcada como sintética por el dominio del correo
--     @ejemplo.lanops.eus. Sin DNI, fecha de nacimiento ni dirección (principio de minimización).
--     En el vídeo y la memoria se dice que es una persona de demostración.
--   · su verificación (documental, Tecnun, "demo sintética") para enseñar el certificado con perfil verificado;
--   · sus preferencias: Donostia y jornada completa como no negociables; excluye ofertas sin empresa
--     identificada (las de Lanbide), así ENCAJE solo evalúa la vacante de demo (1 llamada a Claude);
--   · la empresa Ceit (Donostia, centro tecnológico) y su oferta real publicada en su portal de empleo
--     (https://ceit.talentclue.com/es/node/117094440/4590), copiada el 07-oct-2026, fuente = 'manual'.
--     Es una candidatura abierta a personal investigador (decisión 96: demo con empresa con nombre).
-- Una sola sentencia: o entra todo o nada. Si se ejecuta dos veces falla por el correo único (no duplica).
-- Devuelve el id de la persona y de la vacante: el enlace de ENCAJE se genera con n8n/LANOPS-ENCAJE/generar-enlace.js.
WITH
usr AS (
  INSERT INTO lanops.usuarios (nombre, email, ciudad, titulacion, estado_verificacion, visibilidad,
                               fecha_alta, consentimiento_fecha, cv_texto)
  VALUES ('Irati Goenaga', 'irati.goenaga@ejemplo.lanops.eus', 'Donostia',
          'Máster en Ingeniería Industrial', 'verificado', true, CURRENT_DATE, CURRENT_DATE,
'Irati Goenaga · Donostia · irati.goenaga@ejemplo.lanops.eus
(Persona de demostración de LANOPS: datos ficticios.)

FORMACIÓN
- Máster Universitario en Ingeniería Industrial. Tecnun - Universidad de Navarra (2024-2026).
  TFM: "Modelado por elementos finitos de la degradación térmica en celdas de batería de ion-litio para movilidad eléctrica" (9,1).
- Grado en Ingeniería en Tecnologías Industriales. Tecnun - Universidad de Navarra (2020-2024).
  TFG: "Caracterización mecánica de piezas de Ti-6Al-4V fabricadas por fusión láser en lecho de polvo" (9,0).

EXPERIENCIA
- Becaria de investigación en el laboratorio de materiales de la universidad (sep 2024 - jun 2026, 20 h/semana):
  ensayos de tracción y fatiga, preparación metalográfica, microscopía óptica y electrónica (SEM),
  tratamiento de datos en Python y redacción de informes para un proyecto con empresa.
- Prácticas en una empresa de componentes de automoción de Gipuzkoa (jun - ago 2023): apoyo a ingeniería
  de procesos, análisis de defectos de estampación e informes 8D.
- Coautora de un póster en un congreso nacional de materiales (2025).

HABILIDADES
- Python (pandas, NumPy, SciPy), MATLAB/Simulink, Abaqus y ANSYS (elementos finitos), SolidWorks, LaTeX, Git básico.
- Diseño de experimentos, análisis de datos de ensayo, redacción técnica.

IDIOMAS
- Euskera C1, castellano nativo, inglés C1 (Cambridge Advanced), francés A2.

OTROS
- Carné B. Voluntaria en divulgación científica para estudiantes de secundaria.

QUÉ BUSCO
- Incorporarme a un centro tecnológico en I+D aplicada (fabricación avanzada, energía y baterías,
  transporte sostenible), en Donostia, con jornada completa y, a ser posible, opción de doctorado industrial.')
  RETURNING id
),
ver AS (
  INSERT INTO lanops.verificaciones (usuario, entidad, tipo, fecha, estado, verificado_por)
  SELECT usr.id, (SELECT id FROM lanops.entidades WHERE nombre = 'Tecnun'), 'documental', CURRENT_DATE,
         'aprobada', 'demo sintética'
  FROM usr
  RETURNING id
),
pref AS (
  INSERT INTO lanops.preferencias (usuario, tipo, clave, valor, peso)
  SELECT usr.id, x.tipo, x.clave, x.valor, x.peso
  FROM usr, (VALUES
    ('duro',      'municipio',        'Donostia',                              NULL::int),
    ('duro',      'jornada',          'completa',                              NULL),
    ('exclusion', 'empresa',          '(Lanbide, sin identificar)',            NULL),
    ('peso',      'puesto_objetivo',  'Investigadora junior en I+D aplicada',  5),
    ('peso',      'sector',           'I+D',                                   4),
    ('peso',      'situacion_actual', 'recien_graduado',                       3),
    ('peso',      'modalidad',        'hibrida',                               3),
    ('peso',      'idioma',           'ingles',                                3)
  ) AS x(tipo, clave, valor, peso)
  RETURNING id
),
emp AS (
  INSERT INTO lanops.empresas (nombre, sector, ciudad, anillo, tamano, url_web, url_empleo,
                               tipo_lectura, fallos_seguidos, activa)
  VALUES ('Ceit', 'I+D', 'Donostia', 1, 'grande', 'https://www.ceit.es',
          'https://ceit.talentclue.com/es', 'manual', 0, true)
  RETURNING id
),
vac AS (
  INSERT INTO lanops.vacantes (empresa, puesto, requisitos, contrato, jornada, ubicacion, salario_min,
                               estado, fuente, url_origen, codigo_externo, hash, fecha_pub, vista_en)
  SELECT emp.id,
         'Personal investigador en I+D (ingeniería, ciencias o afines) · candidatura abierta',
'En CEIT buscamos personas con talento, curiosidad y vocación investigadora que quieran formar parte de un entorno dinámico y multidisciplinar. Nuestra misión es contribuir a mejorar la competitividad del tejido empresarial a través de proyectos de investigación aplicada que generen soluciones avanzadas basadas en la excelencia científica y tecnológica. Además, apostamos por la formación de jóvenes investigadores que lideren los cambios necesarios para llevar a las empresas al más alto nivel de competitividad internacional.

Si tienes formación en ingeniería, ciencias o áreas afines, y te motiva trabajar en proyectos de vanguardia en ámbitos como la fabricación avanzada, transporte sostenible y la energía, la sostenibilidad o la digitalización industrial ¡nos encantaría conocerte!

Por favor enviarnos tu CV en y responder a las preguntas del cuestionario sobre tu interés profesional.

Ofrecemos:
Horario flexible: entrada flexible de 2h y jornada intensiva los viernes y verano
Teletrabajo: 6 días al mes
Formación contínua: técnica y de idiomas
Conciliación de la vida personal y laboral
33 días de vacaciones al año
Instalaciones deportivas para fomentar la práctica del deporte
Matrícula universitaria gratuita en la Universidad de Navarra
Club de Compra: descuentos en tiendas, viajes, hoteles....
Acceso a seguro médico Premium en la Clínica Universidad de Navarra
Buen clima laboral basado en la confianza y el trabajo en equipo
Incorporación en una empresa tecnológica internacional de vanguardia

Requisitos
Titulación requerida: Ingeniería, ciencias o áreas afines.
Ubicación: San Sebastián (España)
Tipo de Contrato: Indefinido
Jornada laboral: Jornada completa
Sector: Internet y tecnología
Vacantes: 1
Disciplina: I+D
Modalidad de trabajo: Híbrida',
         'indefinido', 'completa', 'Donostia / San Sebastián', NULL,
         'abierta', 'manual', 'https://ceit.talentclue.com/es/node/117094440/4590', 'ceit-tc-117094440-4590',
         md5('https://ceit.talentclue.com/es/node/117094440/4590'), CURRENT_DATE, CURRENT_DATE
  FROM emp
  RETURNING id
)
SELECT (SELECT id FROM usr) AS usuario_demo,
       (SELECT id FROM vac) AS vacante_demo,
       (SELECT id FROM emp) AS empresa_ceit,
       (SELECT count(*) FROM pref) AS preferencias,
       (SELECT count(*) FROM ver) AS verificaciones;
