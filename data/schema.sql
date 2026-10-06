-- LANOPS · esquema de Postgres (esquema lanops)
-- Generado desde data/esquema.py (misma estructura que el .mdb de Access).
-- Tablas en minúscula; COUNTER -> serial, TEXT(n) -> varchar(n), MEMO -> text,
-- LONG -> integer, SINGLE -> real, YESNO -> boolean, DATETIME -> timestamp.
-- Reglas de validación de Access -> CHECK. Descripciones -> COMMENT.
-- Se ejecuta con el usuario marcos (dueño del esquema lanops), todo de una vez.

CREATE TABLE lanops.configuracion (
  clave varchar(40) NOT NULL,
  valor varchar(100) NOT NULL,
  descripcion varchar(150),
  CONSTRAINT pk_configuracion PRIMARY KEY (clave)
);
COMMENT ON TABLE lanops.configuracion IS 'Parámetros de negocio (cupo, caducidad, umbrales). Ningún número de negocio vive en los flujos.';
COMMENT ON COLUMN lanops.configuracion.clave IS 'Nombre del parámetro';
COMMENT ON COLUMN lanops.configuracion.valor IS 'Valor del parámetro';
COMMENT ON COLUMN lanops.configuracion.descripcion IS 'Para qué sirve';

CREATE TABLE lanops.entidades (
  id serial,
  nombre varchar(100) NOT NULL,
  tipo varchar(15) NOT NULL CONSTRAINT ck_entidades_tipo CHECK (tipo IN ('universidad', 'social', 'publica')),
  dominio_email varchar(60),
  contacto varchar(150),
  activa boolean DEFAULT true,
  CONSTRAINT pk_entidades PRIMARY KEY (id),
  CONSTRAINT uq_entidades_nombre UNIQUE (nombre)
);
COMMENT ON TABLE lanops.entidades IS 'Entidades que pueden verificar a un usuario (universidad, entidad social, servicio público).';
COMMENT ON COLUMN lanops.entidades.id IS 'Identificador';
COMMENT ON COLUMN lanops.entidades.nombre IS 'Nombre de la entidad';
COMMENT ON COLUMN lanops.entidades.tipo IS 'universidad, social o publica';
COMMENT ON COLUMN lanops.entidades.dominio_email IS 'Dominio de correo para la verificación automática';
COMMENT ON COLUMN lanops.entidades.contacto IS 'Persona o correo de contacto';
COMMENT ON COLUMN lanops.entidades.activa IS 'Si puede verificar hoy';

CREATE TABLE lanops.habilidades (
  id serial,
  nombre varchar(60) NOT NULL,
  categoria varchar(40) NOT NULL CONSTRAINT ck_habilidades_categoria CHECK (categoria IN ('tecnica', 'idioma', 'transversal', 'herramienta')),
  CONSTRAINT pk_habilidades PRIMARY KEY (id),
  CONSTRAINT uq_habilidades_nombre UNIQUE (nombre)
);
COMMENT ON TABLE lanops.habilidades IS 'Catálogo común de habilidades: base de los filtros finos.';
COMMENT ON COLUMN lanops.habilidades.id IS 'Identificador';
COMMENT ON COLUMN lanops.habilidades.nombre IS 'Nombre de la habilidad';
COMMENT ON COLUMN lanops.habilidades.categoria IS 'tecnica, idioma, transversal o herramienta';

CREATE TABLE lanops.evaluadores (
  id serial,
  nombre varchar(60) NOT NULL,
  tipo varchar(10) NOT NULL CONSTRAINT ck_evaluadores_tipo CHECK (tipo IN ('ia', 'humano')),
  version_rubrica varchar(30) NOT NULL,
  modelo varchar(60),
  prompt text,
  activo boolean DEFAULT true,
  fecha_alta timestamp,
  CONSTRAINT pk_evaluadores PRIMARY KEY (id)
);
COMMENT ON TABLE lanops.evaluadores IS 'Quién rellena una evaluación: una versión del motor de IA o una persona.';
COMMENT ON COLUMN lanops.evaluadores.id IS 'Identificador';
COMMENT ON COLUMN lanops.evaluadores.nombre IS 'Nombre del evaluador';
COMMENT ON COLUMN lanops.evaluadores.tipo IS 'ia o humano';
COMMENT ON COLUMN lanops.evaluadores.version_rubrica IS 'Versión de la rúbrica que aplica';
COMMENT ON COLUMN lanops.evaluadores.modelo IS 'Modelo de IA; vacío si es humano';
COMMENT ON COLUMN lanops.evaluadores.prompt IS 'Instrucciones vigentes del evaluador';
COMMENT ON COLUMN lanops.evaluadores.activo IS 'Solo un evaluador de IA activo a la vez';
COMMENT ON COLUMN lanops.evaluadores.fecha_alta IS 'Desde cuándo evalúa';

CREATE TABLE lanops.empresas (
  id serial,
  nombre varchar(100) NOT NULL,
  sector varchar(60),
  ciudad varchar(60),
  anillo integer NOT NULL DEFAULT 1 CONSTRAINT ck_empresas_anillo CHECK (anillo BETWEEN 1 AND 3),
  tamano varchar(20) CONSTRAINT ck_empresas_tamano CHECK (tamano IN ('micro', 'pequeña', 'mediana', 'grande')),
  url_web varchar(255),
  url_empleo varchar(255),
  tipo_lectura varchar(10) CONSTRAINT ck_empresas_tipo_lectura CHECK (tipo_lectura IN ('jsonld', 'html', 'ats', 'pdf', 'manual', 'ninguna')),
  ultima_lectura timestamp,
  fallos_seguidos integer DEFAULT 0 CONSTRAINT ck_empresas_fallos_seguidos CHECK (fallos_seguidos >= 0),
  activa boolean DEFAULT true,
  CONSTRAINT pk_empresas PRIMARY KEY (id)
);
COMMENT ON TABLE lanops.empresas IS 'Empresas que publican vacantes. anillo 1 = Gipuzkoa.';
COMMENT ON COLUMN lanops.empresas.id IS 'Identificador';
COMMENT ON COLUMN lanops.empresas.nombre IS 'Razón comercial';
COMMENT ON COLUMN lanops.empresas.sector IS 'Sector de actividad';
COMMENT ON COLUMN lanops.empresas.ciudad IS 'Municipio de la sede';
COMMENT ON COLUMN lanops.empresas.anillo IS '1 Gipuzkoa, 2 Madrid, 3 resto';
COMMENT ON COLUMN lanops.empresas.tamano IS 'micro, pequeña, mediana o grande';
COMMENT ON COLUMN lanops.empresas.url_web IS 'Web corporativa';
COMMENT ON COLUMN lanops.empresas.url_empleo IS 'Página de empleo que lee el agente';
COMMENT ON COLUMN lanops.empresas.tipo_lectura IS 'Cómo se leen sus vacantes';
COMMENT ON COLUMN lanops.empresas.ultima_lectura IS 'Última lectura del agente';
COMMENT ON COLUMN lanops.empresas.fallos_seguidos IS 'Lecturas fallidas seguidas; alerta con 2 o más';
COMMENT ON COLUMN lanops.empresas.activa IS 'Si se sigue leyendo';

CREATE TABLE lanops.usuarios (
  id serial,
  nombre varchar(100) NOT NULL,
  email varchar(150) NOT NULL,
  ciudad varchar(60),
  titulacion varchar(100),
  estado_verificacion varchar(15) NOT NULL DEFAULT 'sin_verificar' CONSTRAINT ck_usuarios_estado_verificacion CHECK (estado_verificacion IN ('sin_verificar', 'pendiente', 'verificado', 'revocado')),
  recomendado_por integer,
  visibilidad boolean DEFAULT true,
  fecha_alta timestamp NOT NULL DEFAULT CURRENT_DATE,
  consentimiento_fecha timestamp,
  cv_texto text,
  CONSTRAINT pk_usuarios PRIMARY KEY (id),
  CONSTRAINT uq_usuarios_email UNIQUE (email)
);
COMMENT ON TABLE lanops.usuarios IS 'Personas que buscan empleo. Entrada abierta; la verificación es opcional.';
COMMENT ON COLUMN lanops.usuarios.id IS 'Identificador';
COMMENT ON COLUMN lanops.usuarios.nombre IS 'Nombre y apellidos';
COMMENT ON COLUMN lanops.usuarios.email IS 'Correo; único';
COMMENT ON COLUMN lanops.usuarios.ciudad IS 'Municipio de residencia';
COMMENT ON COLUMN lanops.usuarios.titulacion IS 'Titulación; vacío si no tiene';
COMMENT ON COLUMN lanops.usuarios.estado_verificacion IS 'sin_verificar, pendiente, verificado o revocado';
COMMENT ON COLUMN lanops.usuarios.recomendado_por IS 'Usuario que lo recomendó (autorreferencia)';
COMMENT ON COLUMN lanops.usuarios.visibilidad IS 'Si su perfil es visible en la red';
COMMENT ON COLUMN lanops.usuarios.fecha_alta IS 'Fecha de registro';
COMMENT ON COLUMN lanops.usuarios.consentimiento_fecha IS 'Fecha del consentimiento RGPD';
COMMENT ON COLUMN lanops.usuarios.cv_texto IS 'Texto del currículum (sin DNI, fecha de nacimiento ni dirección)';
ALTER TABLE lanops.usuarios ADD CONSTRAINT fk_usuarios_recomendado FOREIGN KEY (recomendado_por) REFERENCES lanops.usuarios (id);

CREATE TABLE lanops.verificaciones (
  id serial,
  usuario integer NOT NULL,
  entidad integer NOT NULL,
  tipo varchar(20) NOT NULL CONSTRAINT ck_verificaciones_tipo CHECK (tipo IN ('email_institucional', 'documental', 'aval')),
  fecha timestamp NOT NULL DEFAULT CURRENT_DATE,
  estado varchar(12) NOT NULL DEFAULT 'pendiente' CONSTRAINT ck_verificaciones_estado CHECK (estado IN ('pendiente', 'aprobada', 'rechazada', 'revocada')),
  verificado_por varchar(60),
  CONSTRAINT pk_verificaciones PRIMARY KEY (id),
  CONSTRAINT fk_verificaciones_usuario FOREIGN KEY (usuario) REFERENCES lanops.usuarios (id),
  CONSTRAINT fk_verificaciones_entidad FOREIGN KEY (entidad) REFERENCES lanops.entidades (id)
);
COMMENT ON TABLE lanops.verificaciones IS 'Cada vez que una entidad comprueba a un usuario.';
COMMENT ON COLUMN lanops.verificaciones.id IS 'Identificador';
COMMENT ON COLUMN lanops.verificaciones.usuario IS 'Usuario verificado';
COMMENT ON COLUMN lanops.verificaciones.entidad IS 'Entidad que verifica';
COMMENT ON COLUMN lanops.verificaciones.tipo IS 'email_institucional, documental o aval';
COMMENT ON COLUMN lanops.verificaciones.fecha IS 'Fecha de la verificación';
COMMENT ON COLUMN lanops.verificaciones.estado IS 'pendiente, aprobada, rechazada o revocada';
COMMENT ON COLUMN lanops.verificaciones.verificado_por IS 'Quién la aprobó o sistema';

CREATE TABLE lanops.vacantes (
  id serial,
  empresa integer NOT NULL,
  puesto varchar(150) NOT NULL,
  requisitos text,
  contrato varchar(30) CONSTRAINT ck_vacantes_contrato CHECK (contrato IN ('indefinido', 'temporal', 'practicas', 'otro')),
  jornada varchar(20) CONSTRAINT ck_vacantes_jornada CHECK (jornada IN ('completa', 'parcial', 'indiferente')),
  ubicacion varchar(60),
  salario_min integer CONSTRAINT ck_vacantes_salario_min CHECK (salario_min >= 0),
  estado varchar(10) NOT NULL DEFAULT 'abierta' CONSTRAINT ck_vacantes_estado CHECK (estado IN ('abierta', 'cerrada')),
  fuente varchar(10) NOT NULL CONSTRAINT ck_vacantes_fuente CHECK (fuente IN ('usuario', 'lanbide', 'api', 'agente', 'manual')),
  url_origen varchar(255),
  codigo_externo varchar(30),
  hash varchar(32) NOT NULL,
  fecha_pub timestamp,
  vista_en timestamp,
  CONSTRAINT pk_vacantes PRIMARY KEY (id),
  CONSTRAINT uq_vacantes_hash UNIQUE (hash),
  CONSTRAINT fk_vacantes_empresa FOREIGN KEY (empresa) REFERENCES lanops.empresas (id)
);
COMMENT ON TABLE lanops.vacantes IS 'Ofertas de empleo, vengan de donde vengan.';
COMMENT ON COLUMN lanops.vacantes.id IS 'Identificador';
COMMENT ON COLUMN lanops.vacantes.empresa IS 'Empresa que la publica';
COMMENT ON COLUMN lanops.vacantes.puesto IS 'Título del puesto';
COMMENT ON COLUMN lanops.vacantes.requisitos IS 'Requisitos tal como se publicaron';
COMMENT ON COLUMN lanops.vacantes.contrato IS 'indefinido, temporal, practicas u otro';
COMMENT ON COLUMN lanops.vacantes.jornada IS 'completa, parcial o indiferente';
COMMENT ON COLUMN lanops.vacantes.ubicacion IS 'Municipio del puesto';
COMMENT ON COLUMN lanops.vacantes.salario_min IS 'Euros brutos al año; vacío si no consta';
COMMENT ON COLUMN lanops.vacantes.estado IS 'abierta o cerrada';
COMMENT ON COLUMN lanops.vacantes.fuente IS 'usuario, lanbide, api, agente o manual';
COMMENT ON COLUMN lanops.vacantes.url_origen IS 'Dónde se publicó';
COMMENT ON COLUMN lanops.vacantes.codigo_externo IS 'Código de Lanbide o del ATS';
COMMENT ON COLUMN lanops.vacantes.hash IS 'Huella para no duplicar la vacante';
COMMENT ON COLUMN lanops.vacantes.fecha_pub IS 'Fecha de publicación';
COMMENT ON COLUMN lanops.vacantes.vista_en IS 'Última vez que se vio publicada';

CREATE TABLE lanops.usuario_habilidad (
  usuario integer NOT NULL,
  habilidad integer NOT NULL,
  nivel integer NOT NULL CONSTRAINT ck_usuario_habilidad_nivel CHECK (nivel BETWEEN 1 AND 5),
  CONSTRAINT pk_usuario_habilidad PRIMARY KEY (usuario, habilidad),
  CONSTRAINT fk_uh_usuario FOREIGN KEY (usuario) REFERENCES lanops.usuarios (id),
  CONSTRAINT fk_uh_habilidad FOREIGN KEY (habilidad) REFERENCES lanops.habilidades (id)
);
COMMENT ON TABLE lanops.usuario_habilidad IS 'N:M usuario-habilidad con nivel.';
COMMENT ON COLUMN lanops.usuario_habilidad.usuario IS 'Usuario';
COMMENT ON COLUMN lanops.usuario_habilidad.habilidad IS 'Habilidad del catálogo';
COMMENT ON COLUMN lanops.usuario_habilidad.nivel IS 'Nivel de 1 a 5';

CREATE TABLE lanops.preferencias (
  id serial,
  usuario integer NOT NULL,
  tipo varchar(10) NOT NULL CONSTRAINT ck_preferencias_tipo CHECK (tipo IN ('duro', 'peso', 'exclusion')),
  clave varchar(40) NOT NULL CONSTRAINT ck_preferencias_clave CHECK (clave IN ('municipio', 'radio_km', 'jornada', 'contrato', 'salario_min', 'modalidad', 'fecha_inicio_max', 'permiso_trabajo', 'euskera', 'sector', 'tamano', 'idioma', 'estabilidad', 'ett', 'palabra', 'empresa', 'movilidad', 'turnos', 'puesto_objetivo', 'situacion_actual')),
  valor varchar(60) NOT NULL,
  peso integer CONSTRAINT ck_preferencias_peso CHECK (peso BETWEEN 1 AND 5),
  fecha_mod timestamp DEFAULT CURRENT_DATE,
  CONSTRAINT pk_preferencias PRIMARY KEY (id),
  CONSTRAINT fk_preferencias_usuario FOREIGN KEY (usuario) REFERENCES lanops.usuarios (id)
);
COMMENT ON TABLE lanops.preferencias IS 'Perfil de búsqueda: qué no negocia (duro), qué prefiere con peso y qué excluye.';
COMMENT ON COLUMN lanops.preferencias.id IS 'Identificador';
COMMENT ON COLUMN lanops.preferencias.usuario IS 'Usuario';
COMMENT ON COLUMN lanops.preferencias.tipo IS 'duro, peso o exclusion';
COMMENT ON COLUMN lanops.preferencias.clave IS 'Qué se filtra u ordena';
COMMENT ON COLUMN lanops.preferencias.valor IS 'Valor de la preferencia';
COMMENT ON COLUMN lanops.preferencias.peso IS '1 a 5 si tipo = peso';
COMMENT ON COLUMN lanops.preferencias.fecha_mod IS 'Última modificación';
CREATE UNIQUE INDEX uq_preferencias ON lanops.preferencias (usuario, tipo, clave, valor);

CREATE TABLE lanops.evaluaciones (
  id serial,
  usuario integer NOT NULL,
  vacante integer NOT NULL,
  evaluador integer NOT NULL,
  fecha timestamp NOT NULL DEFAULT CURRENT_DATE,
  d1_match_cv integer NOT NULL CONSTRAINT ck_evaluaciones_d1_match_cv CHECK (d1_match_cv BETWEEN 1 AND 5),
  d2_north_star integer NOT NULL CONSTRAINT ck_evaluaciones_d2_north_star CHECK (d2_north_star BETWEEN 1 AND 5),
  d3_compensacion integer NOT NULL CONSTRAINT ck_evaluaciones_d3_compensacion CHECK (d3_compensacion BETWEEN 1 AND 5),
  d4_cultura integer NOT NULL CONSTRAINT ck_evaluaciones_d4_cultura CHECK (d4_cultura BETWEEN 1 AND 5),
  d5_red_flags integer NOT NULL CONSTRAINT ck_evaluaciones_d5_red_flags CHECK (d5_red_flags BETWEEN 1 AND 5),
  global real NOT NULL CONSTRAINT ck_evaluaciones_global CHECK (global BETWEEN 1 AND 5),
  global_personal real CONSTRAINT ck_evaluaciones_global_personal CHECK (global_personal BETWEEN 1 AND 5),
  banda varchar(6) NOT NULL CONSTRAINT ck_evaluaciones_banda CHECK (banda IN ('Alta', 'Media', 'Baja')),
  explicacion text,
  hueco text,
  hash_cv varchar(32) NOT NULL,
  CONSTRAINT pk_evaluaciones PRIMARY KEY (id),
  CONSTRAINT fk_evaluaciones_usuario FOREIGN KEY (usuario) REFERENCES lanops.usuarios (id),
  CONSTRAINT fk_evaluaciones_vacante FOREIGN KEY (vacante) REFERENCES lanops.vacantes (id),
  CONSTRAINT fk_evaluaciones_evaluador FOREIGN KEY (evaluador) REFERENCES lanops.evaluadores (id)
);
COMMENT ON TABLE lanops.evaluaciones IS 'N:M usuario-vacante: hoja de evaluación de un evaluador.';
COMMENT ON COLUMN lanops.evaluaciones.id IS 'Identificador';
COMMENT ON COLUMN lanops.evaluaciones.usuario IS 'Usuario evaluado';
COMMENT ON COLUMN lanops.evaluaciones.vacante IS 'Vacante contra la que se evalúa';
COMMENT ON COLUMN lanops.evaluaciones.evaluador IS 'Quién evalúa';
COMMENT ON COLUMN lanops.evaluaciones.fecha IS 'Fecha de la evaluación';
COMMENT ON COLUMN lanops.evaluaciones.d1_match_cv IS 'Encaje de habilidades y experiencia con la vacante, 1 a 5';
COMMENT ON COLUMN lanops.evaluaciones.d2_north_star IS 'Encaje con el tipo de puesto que busca el usuario, 1 a 5';
COMMENT ON COLUMN lanops.evaluaciones.d3_compensacion IS 'Salario frente al mercado, 1 a 5';
COMMENT ON COLUMN lanops.evaluaciones.d4_cultura IS 'Cultura, estabilidad y teletrabajo, 1 a 5';
COMMENT ON COLUMN lanops.evaluaciones.d5_red_flags IS 'Alertas y bloqueos, 1 a 5 (5 = sin alertas)';
COMMENT ON COLUMN lanops.evaluaciones.global IS 'Puntuación holística 1 a 5; va al certificado (x20 = %)';
COMMENT ON COLUMN lanops.evaluaciones.global_personal IS 'Reordenación por los pesos del usuario';
COMMENT ON COLUMN lanops.evaluaciones.banda IS 'Alta (>=4), Media (3-3,9) o Baja (<3)';
COMMENT ON COLUMN lanops.evaluaciones.explicacion IS 'Tres líneas de explicación';
COMMENT ON COLUMN lanops.evaluaciones.hueco IS 'Qué le falta para subir un punto';
COMMENT ON COLUMN lanops.evaluaciones.hash_cv IS 'Huella del CV evaluado (caché)';
CREATE UNIQUE INDEX uq_evaluaciones ON lanops.evaluaciones (usuario, vacante, evaluador, hash_cv);

CREATE TABLE lanops.feedback (
  id serial,
  usuario integer NOT NULL,
  vacante integer NOT NULL,
  veredicto varchar(22) NOT NULL CONSTRAINT ck_feedback_veredicto CHECK (veredicto IN ('descartada', 'guardada', 'postulada', 'entrevista', 'oferta', 'descartada_por_empresa')),
  motivo varchar(30) CONSTRAINT ck_feedback_motivo CHECK (motivo IN ('sector', 'salario', 'lejos', 'tarea', 'empresa', 'otro')),
  fecha timestamp NOT NULL DEFAULT CURRENT_DATE,
  CONSTRAINT pk_feedback PRIMARY KEY (id),
  CONSTRAINT fk_feedback_usuario FOREIGN KEY (usuario) REFERENCES lanops.usuarios (id),
  CONSTRAINT fk_feedback_vacante FOREIGN KEY (vacante) REFERENCES lanops.vacantes (id)
);
COMMENT ON TABLE lanops.feedback IS 'N:M usuario-vacante: qué hace el usuario con cada vacante.';
COMMENT ON COLUMN lanops.feedback.id IS 'Identificador';
COMMENT ON COLUMN lanops.feedback.usuario IS 'Usuario';
COMMENT ON COLUMN lanops.feedback.vacante IS 'Vacante';
COMMENT ON COLUMN lanops.feedback.veredicto IS 'Qué decidió o qué pasó';
COMMENT ON COLUMN lanops.feedback.motivo IS 'Solo si la descarta';
COMMENT ON COLUMN lanops.feedback.fecha IS 'Fecha';

CREATE TABLE lanops.certificados (
  id serial,
  usuario integer NOT NULL,
  vacante integer NOT NULL,
  evaluacion integer NOT NULL,
  codigo varchar(36) NOT NULL,
  firma varchar(64) NOT NULL,
  fecha_emision timestamp NOT NULL DEFAULT CURRENT_DATE,
  fecha_caducidad timestamp NOT NULL,
  estado varchar(10) NOT NULL DEFAULT 'vigente' CONSTRAINT ck_certificados_estado CHECK (estado IN ('vigente', 'caducado', 'revocado')),
  veces_verificado integer DEFAULT 0 CONSTRAINT ck_certificados_veces_verificado CHECK (veces_verificado >= 0),
  CONSTRAINT pk_certificados PRIMARY KEY (id),
  CONSTRAINT uq_certificados_codigo UNIQUE (codigo),
  CONSTRAINT fk_certificados_usuario FOREIGN KEY (usuario) REFERENCES lanops.usuarios (id),
  CONSTRAINT fk_certificados_vacante FOREIGN KEY (vacante) REFERENCES lanops.vacantes (id),
  CONSTRAINT fk_certificados_evaluacion FOREIGN KEY (evaluacion) REFERENCES lanops.evaluaciones (id)
);
COMMENT ON TABLE lanops.certificados IS 'Certificado de congruencia para una vacante; nace de una evaluación.';
COMMENT ON COLUMN lanops.certificados.id IS 'Identificador';
COMMENT ON COLUMN lanops.certificados.usuario IS 'Titular';
COMMENT ON COLUMN lanops.certificados.vacante IS 'Vacante objetivo';
COMMENT ON COLUMN lanops.certificados.evaluacion IS 'Evaluación de la que nace';
COMMENT ON COLUMN lanops.certificados.codigo IS 'UUID; va en la URL de verificación';
COMMENT ON COLUMN lanops.certificados.firma IS 'HMAC-SHA256 de codigo|usuario|vacante|global|fecha';
COMMENT ON COLUMN lanops.certificados.fecha_emision IS 'Fecha de emisión';
COMMENT ON COLUMN lanops.certificados.fecha_caducidad IS 'Emisión + 30 días';
COMMENT ON COLUMN lanops.certificados.estado IS 'vigente, caducado o revocado';
COMMENT ON COLUMN lanops.certificados.veces_verificado IS 'Veces que una empresa lo comprobó';
