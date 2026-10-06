CREATE TABLE [CONFIGURACION] (
  [clave] TEXT(40) NOT NULL,
  [valor] TEXT(100) NOT NULL,
  [descripcion] TEXT(150),
  CONSTRAINT pk_configuracion PRIMARY KEY (clave)
);

CREATE TABLE [ENTIDADES] (
  [id] COUNTER,
  [nombre] TEXT(100) NOT NULL,
  [tipo] TEXT(15) NOT NULL,
  [dominio_email] TEXT(60),
  [contacto] TEXT(150),
  [activa] YESNO,
  CONSTRAINT pk_entidades PRIMARY KEY (id),
  CONSTRAINT uq_entidades_nombre UNIQUE (nombre)
);

CREATE TABLE [HABILIDADES] (
  [id] COUNTER,
  [nombre] TEXT(60) NOT NULL,
  [categoria] TEXT(40) NOT NULL,
  CONSTRAINT pk_habilidades PRIMARY KEY (id),
  CONSTRAINT uq_habilidades_nombre UNIQUE (nombre)
);

CREATE TABLE [EVALUADORES] (
  [id] COUNTER,
  [nombre] TEXT(60) NOT NULL,
  [tipo] TEXT(10) NOT NULL,
  [version_rubrica] TEXT(30) NOT NULL,
  [modelo] TEXT(60),
  [prompt] MEMO,
  [activo] YESNO,
  [fecha_alta] DATETIME,
  CONSTRAINT pk_evaluadores PRIMARY KEY (id)
);

CREATE TABLE [EMPRESAS] (
  [id] COUNTER,
  [nombre] TEXT(100) NOT NULL,
  [sector] TEXT(60),
  [ciudad] TEXT(60),
  [anillo] LONG NOT NULL,
  [tamano] TEXT(20),
  [url_web] TEXT(255),
  [url_empleo] TEXT(255),
  [tipo_lectura] TEXT(10),
  [ultima_lectura] DATETIME,
  [fallos_seguidos] LONG,
  [activa] YESNO,
  CONSTRAINT pk_empresas PRIMARY KEY (id)
);

CREATE TABLE [USUARIOS] (
  [id] COUNTER,
  [nombre] TEXT(100) NOT NULL,
  [email] TEXT(150) NOT NULL,
  [ciudad] TEXT(60),
  [titulacion] TEXT(100),
  [estado_verificacion] TEXT(15) NOT NULL,
  [recomendado_por] LONG,
  [visibilidad] YESNO,
  [fecha_alta] DATETIME NOT NULL,
  [consentimiento_fecha] DATETIME,
  [cv_texto] MEMO,
  CONSTRAINT pk_usuarios PRIMARY KEY (id),
  CONSTRAINT uq_usuarios_email UNIQUE (email)
);

ALTER TABLE USUARIOS ADD CONSTRAINT fk_usuarios_recomendado FOREIGN KEY (recomendado_por) REFERENCES USUARIOS (id);

CREATE TABLE [VERIFICACIONES] (
  [id] COUNTER,
  [usuario] LONG NOT NULL,
  [entidad] LONG NOT NULL,
  [tipo] TEXT(20) NOT NULL,
  [fecha] DATETIME NOT NULL,
  [estado] TEXT(12) NOT NULL,
  [verificado_por] TEXT(60),
  CONSTRAINT pk_verificaciones PRIMARY KEY (id),
  CONSTRAINT fk_verificaciones_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id),
  CONSTRAINT fk_verificaciones_entidad FOREIGN KEY (entidad) REFERENCES ENTIDADES (id)
);

CREATE TABLE [VACANTES] (
  [id] COUNTER,
  [empresa] LONG NOT NULL,
  [puesto] TEXT(150) NOT NULL,
  [requisitos] MEMO,
  [contrato] TEXT(30),
  [jornada] TEXT(20),
  [ubicacion] TEXT(60),
  [salario_min] LONG,
  [estado] TEXT(10) NOT NULL,
  [fuente] TEXT(10) NOT NULL,
  [url_origen] TEXT(255),
  [codigo_externo] TEXT(30),
  [hash] TEXT(32) NOT NULL,
  [fecha_pub] DATETIME,
  [vista_en] DATETIME,
  CONSTRAINT pk_vacantes PRIMARY KEY (id),
  CONSTRAINT uq_vacantes_hash UNIQUE (hash),
  CONSTRAINT fk_vacantes_empresa FOREIGN KEY (empresa) REFERENCES EMPRESAS (id)
);

CREATE TABLE [USUARIO_HABILIDAD] (
  [usuario] LONG NOT NULL,
  [habilidad] LONG NOT NULL,
  [nivel] LONG NOT NULL,
  CONSTRAINT pk_usuario_habilidad PRIMARY KEY (usuario, habilidad),
  CONSTRAINT fk_uh_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id),
  CONSTRAINT fk_uh_habilidad FOREIGN KEY (habilidad) REFERENCES HABILIDADES (id)
);

CREATE TABLE [PREFERENCIAS] (
  [id] COUNTER,
  [usuario] LONG NOT NULL,
  [tipo] TEXT(10) NOT NULL,
  [clave] TEXT(40) NOT NULL,
  [valor] TEXT(60) NOT NULL,
  [peso] LONG,
  [fecha_mod] DATETIME,
  CONSTRAINT pk_preferencias PRIMARY KEY (id),
  CONSTRAINT fk_preferencias_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id)
);

CREATE UNIQUE INDEX uq_preferencias ON PREFERENCIAS (usuario, tipo, clave, valor);

CREATE TABLE [EVALUACIONES] (
  [id] COUNTER,
  [usuario] LONG NOT NULL,
  [vacante] LONG NOT NULL,
  [evaluador] LONG NOT NULL,
  [fecha] DATETIME NOT NULL,
  [d1_match_cv] LONG NOT NULL,
  [d2_north_star] LONG NOT NULL,
  [d3_compensacion] LONG NOT NULL,
  [d4_cultura] LONG NOT NULL,
  [d5_red_flags] LONG NOT NULL,
  [global] SINGLE NOT NULL,
  [global_personal] SINGLE,
  [banda] TEXT(6) NOT NULL,
  [explicacion] MEMO,
  [hueco] MEMO,
  [hash_cv] TEXT(32) NOT NULL,
  CONSTRAINT pk_evaluaciones PRIMARY KEY (id),
  CONSTRAINT fk_evaluaciones_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id),
  CONSTRAINT fk_evaluaciones_vacante FOREIGN KEY (vacante) REFERENCES VACANTES (id),
  CONSTRAINT fk_evaluaciones_evaluador FOREIGN KEY (evaluador) REFERENCES EVALUADORES (id)
);

CREATE UNIQUE INDEX uq_evaluaciones ON EVALUACIONES (usuario, vacante, evaluador, hash_cv);

CREATE TABLE [FEEDBACK] (
  [id] COUNTER,
  [usuario] LONG NOT NULL,
  [vacante] LONG NOT NULL,
  [veredicto] TEXT(22) NOT NULL,
  [motivo] TEXT(30),
  [fecha] DATETIME NOT NULL,
  CONSTRAINT pk_feedback PRIMARY KEY (id),
  CONSTRAINT fk_feedback_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id),
  CONSTRAINT fk_feedback_vacante FOREIGN KEY (vacante) REFERENCES VACANTES (id)
);

CREATE TABLE [CERTIFICADOS] (
  [id] COUNTER,
  [usuario] LONG NOT NULL,
  [vacante] LONG NOT NULL,
  [evaluacion] LONG NOT NULL,
  [codigo] TEXT(36) NOT NULL,
  [firma] TEXT(64) NOT NULL,
  [fecha_emision] DATETIME NOT NULL,
  [fecha_caducidad] DATETIME NOT NULL,
  [estado] TEXT(10) NOT NULL,
  [veces_verificado] LONG,
  CONSTRAINT pk_certificados PRIMARY KEY (id),
  CONSTRAINT uq_certificados_codigo UNIQUE (codigo),
  CONSTRAINT fk_certificados_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id),
  CONSTRAINT fk_certificados_vacante FOREIGN KEY (vacante) REFERENCES VACANTES (id),
  CONSTRAINT fk_certificados_evaluacion FOREIGN KEY (evaluacion) REFERENCES EVALUACIONES (id)
);
