# Esquema único de LANOPS: de aquí salen el DDL de Access (VBA), el schema.ini y las comprobaciones.
# (col, ddl_jet, schema_ini, not_null, descripcion, regla, texto_regla, defecto)
def C(col,ddl,ini,nn,desc,regla=None,txt=None,defecto=None): return dict(col=col,ddl=ddl,ini=ini,nn=nn,desc=desc,regla=regla,txt=txt,defecto=defecto)
def IN(*v): return 'In (' + ','.join('"%s"'%x for x in v) + ')'
T=[]
T.append(('CONFIGURACION','Parámetros de negocio (cupo, caducidad, umbrales). Ningún número de negocio vive en los flujos.',[
 C('clave','TEXT(40)','Text Width 40',True,'Nombre del parámetro'),
 C('valor','TEXT(100)','Text Width 100',True,'Valor del parámetro'),
 C('descripcion','TEXT(150)','Text Width 150',False,'Para qué sirve'),
],['CONSTRAINT pk_configuracion PRIMARY KEY (clave)'],[]))
T.append(('ENTIDADES','Entidades que pueden verificar a un usuario (universidad, entidad social, servicio público).',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('nombre','TEXT(100)','Text Width 100',True,'Nombre de la entidad'),
 C('tipo','TEXT(15)','Text Width 15',True,'universidad, social o publica',IN('universidad','social','publica'),'Tipo: universidad, social o publica'),
 C('dominio_email','TEXT(60)','Text Width 60',False,'Dominio de correo para la verificación automática'),
 C('contacto','TEXT(150)','Text Width 150',False,'Persona o correo de contacto'),
 C('activa','YESNO','Short',False,'Si puede verificar hoy',defecto='-1'),
],['CONSTRAINT pk_entidades PRIMARY KEY (id)','CONSTRAINT uq_entidades_nombre UNIQUE (nombre)'],[]))
T.append(('HABILIDADES','Catálogo común de habilidades: base de los filtros finos.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('nombre','TEXT(60)','Text Width 60',True,'Nombre de la habilidad'),
 C('categoria','TEXT(40)','Text Width 40',True,'tecnica, idioma, transversal o herramienta',IN('tecnica','idioma','transversal','herramienta'),'Categoría: tecnica, idioma, transversal o herramienta'),
],['CONSTRAINT pk_habilidades PRIMARY KEY (id)','CONSTRAINT uq_habilidades_nombre UNIQUE (nombre)'],[]))
T.append(('EVALUADORES','Quién rellena una evaluación: una versión del motor de IA o una persona.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('nombre','TEXT(60)','Text Width 60',True,'Nombre del evaluador'),
 C('tipo','TEXT(10)','Text Width 10',True,'ia o humano',IN('ia','humano'),'Tipo: ia o humano'),
 C('version_rubrica','TEXT(30)','Text Width 30',True,'Versión de la rúbrica que aplica'),
 C('modelo','TEXT(60)','Text Width 60',False,'Modelo de IA; vacío si es humano'),
 C('prompt','MEMO','Memo',False,'Instrucciones vigentes del evaluador'),
 C('activo','YESNO','Short',False,'Solo un evaluador de IA activo a la vez',defecto='-1'),
 C('fecha_alta','DATETIME','DateTime',False,'Desde cuándo evalúa'),
],['CONSTRAINT pk_evaluadores PRIMARY KEY (id)'],[]))
T.append(('EMPRESAS','Empresas que publican vacantes. anillo 1 = Gipuzkoa.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('nombre','TEXT(100)','Text Width 100',True,'Razón comercial'),
 C('sector','TEXT(60)','Text Width 60',False,'Sector de actividad'),
 C('ciudad','TEXT(60)','Text Width 60',False,'Municipio de la sede'),
 C('anillo','LONG','Long',True,'1 Gipuzkoa, 2 Madrid, 3 resto','Between 1 And 3','Anillo: 1, 2 o 3',defecto='1'),
 C('tamano','TEXT(20)','Text Width 20',False,'micro, pequeña, mediana o grande',IN('micro','pequeña','mediana','grande'),'Tamaño: micro, pequeña, mediana o grande'),
 C('url_web','TEXT(255)','Text Width 255',False,'Web corporativa'),
 C('url_empleo','TEXT(255)','Text Width 255',False,'Página de empleo que lee el agente'),
 C('tipo_lectura','TEXT(10)','Text Width 10',False,'Cómo se leen sus vacantes',IN('jsonld','html','ats','pdf','manual','ninguna'),'Lectura: jsonld, html, ats, pdf, manual o ninguna'),
 C('ultima_lectura','DATETIME','DateTime',False,'Última lectura del agente'),
 C('fallos_seguidos','LONG','Long',False,'Lecturas fallidas seguidas; alerta con 2 o más','>=0','No puede ser negativo','0'),
 C('activa','YESNO','Short',False,'Si se sigue leyendo',defecto='-1'),
],['CONSTRAINT pk_empresas PRIMARY KEY (id)'],[]))
T.append(('USUARIOS','Personas que buscan empleo. Entrada abierta; la verificación es opcional.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('nombre','TEXT(100)','Text Width 100',True,'Nombre y apellidos'),
 C('email','TEXT(150)','Text Width 150',True,'Correo; único'),
 C('ciudad','TEXT(60)','Text Width 60',False,'Municipio de residencia'),
 C('titulacion','TEXT(100)','Text Width 100',False,'Titulación; vacío si no tiene'),
 C('estado_verificacion','TEXT(15)','Text Width 15',True,'sin_verificar, pendiente, verificado o revocado',IN('sin_verificar','pendiente','verificado','revocado'),'Estado: sin_verificar, pendiente, verificado o revocado','"sin_verificar"'),
 C('recomendado_por','LONG','Long',False,'Usuario que lo recomendó (autorreferencia)'),
 C('visibilidad','YESNO','Short',False,'Si su perfil es visible en la red',defecto='-1'),
 C('fecha_alta','DATETIME','DateTime',True,'Fecha de registro',defecto='Date()'),
 C('consentimiento_fecha','DATETIME','DateTime',False,'Fecha del consentimiento RGPD'),
 C('cv_texto','MEMO','Memo',False,'Texto del currículum (sin DNI, fecha de nacimiento ni dirección)'),
],['CONSTRAINT pk_usuarios PRIMARY KEY (id)','CONSTRAINT uq_usuarios_email UNIQUE (email)'],
 ['ALTER TABLE USUARIOS ADD CONSTRAINT fk_usuarios_recomendado FOREIGN KEY (recomendado_por) REFERENCES USUARIOS (id)']))
T.append(('VERIFICACIONES','Cada vez que una entidad comprueba a un usuario.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('usuario','LONG','Long',True,'Usuario verificado'),
 C('entidad','LONG','Long',True,'Entidad que verifica'),
 C('tipo','TEXT(20)','Text Width 20',True,'email_institucional, documental o aval',IN('email_institucional','documental','aval'),'Tipo: email_institucional, documental o aval'),
 C('fecha','DATETIME','DateTime',True,'Fecha de la verificación',defecto='Date()'),
 C('estado','TEXT(12)','Text Width 12',True,'pendiente, aprobada, rechazada o revocada',IN('pendiente','aprobada','rechazada','revocada'),'Estado: pendiente, aprobada, rechazada o revocada','"pendiente"'),
 C('verificado_por','TEXT(60)','Text Width 60',False,'Quién la aprobó o sistema'),
],['CONSTRAINT pk_verificaciones PRIMARY KEY (id)',
  'CONSTRAINT fk_verificaciones_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id)',
  'CONSTRAINT fk_verificaciones_entidad FOREIGN KEY (entidad) REFERENCES ENTIDADES (id)'],[]))
T.append(('VACANTES','Ofertas de empleo, vengan de donde vengan.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('empresa','LONG','Long',True,'Empresa que la publica'),
 C('puesto','TEXT(150)','Text Width 150',True,'Título del puesto'),
 C('requisitos','MEMO','Memo',False,'Requisitos tal como se publicaron'),
 C('contrato','TEXT(30)','Text Width 30',False,'indefinido, temporal, practicas u otro',IN('indefinido','temporal','practicas','otro'),'Contrato: indefinido, temporal, practicas u otro'),
 C('jornada','TEXT(20)','Text Width 20',False,'completa, parcial o indiferente',IN('completa','parcial','indiferente'),'Jornada: completa, parcial o indiferente'),
 C('ubicacion','TEXT(60)','Text Width 60',False,'Municipio del puesto'),
 C('salario_min','LONG','Long',False,'Euros brutos al año; vacío si no consta','>=0','No puede ser negativo'),
 C('estado','TEXT(10)','Text Width 10',True,'abierta o cerrada',IN('abierta','cerrada'),'Estado: abierta o cerrada','"abierta"'),
 C('fuente','TEXT(10)','Text Width 10',True,'usuario, lanbide, api, agente o manual',IN('usuario','lanbide','api','agente','manual'),'Fuente: usuario, lanbide, api, agente o manual'),
 C('url_origen','TEXT(255)','Text Width 255',False,'Dónde se publicó'),
 C('codigo_externo','TEXT(30)','Text Width 30',False,'Código de Lanbide o del ATS'),
 C('hash','TEXT(32)','Text Width 32',True,'Huella para no duplicar la vacante'),
 C('fecha_pub','DATETIME','DateTime',False,'Fecha de publicación'),
 C('vista_en','DATETIME','DateTime',False,'Última vez que se vio publicada'),
],['CONSTRAINT pk_vacantes PRIMARY KEY (id)','CONSTRAINT uq_vacantes_hash UNIQUE (hash)',
  'CONSTRAINT fk_vacantes_empresa FOREIGN KEY (empresa) REFERENCES EMPRESAS (id)'],[]))
T.append(('USUARIO_HABILIDAD','N:M usuario-habilidad con nivel.',[
 C('usuario','LONG','Long',True,'Usuario'),
 C('habilidad','LONG','Long',True,'Habilidad del catálogo'),
 C('nivel','LONG','Long',True,'Nivel de 1 a 5','Between 1 And 5','Nivel entre 1 y 5'),
],['CONSTRAINT pk_usuario_habilidad PRIMARY KEY (usuario, habilidad)',
  'CONSTRAINT fk_uh_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id)',
  'CONSTRAINT fk_uh_habilidad FOREIGN KEY (habilidad) REFERENCES HABILIDADES (id)'],[]))
T.append(('PREFERENCIAS','Perfil de búsqueda: qué no negocia (duro), qué prefiere con peso y qué excluye.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('usuario','LONG','Long',True,'Usuario'),
 C('tipo','TEXT(10)','Text Width 10',True,'duro, peso o exclusion',IN('duro','peso','exclusion'),'Tipo: duro, peso o exclusion'),
 C('clave','TEXT(40)','Text Width 40',True,'Qué se filtra u ordena',IN('municipio','radio_km','jornada','contrato','salario_min','modalidad','fecha_inicio_max','permiso_trabajo','euskera','sector','tamano','idioma','estabilidad','ett','palabra','empresa','movilidad','turnos','puesto_objetivo','situacion_actual'),'Clave no admitida'),
 C('valor','TEXT(60)','Text Width 60',True,'Valor de la preferencia'),
 C('peso','LONG','Long',False,'1 a 5 si tipo = peso','Between 1 And 5','Peso entre 1 y 5'),
 C('fecha_mod','DATETIME','DateTime',False,'Última modificación',defecto='Date()'),
],['CONSTRAINT pk_preferencias PRIMARY KEY (id)',
  'CONSTRAINT fk_preferencias_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id)'],
 ['CREATE UNIQUE INDEX uq_preferencias ON PREFERENCIAS (usuario, tipo, clave, valor)']))
T.append(('EVALUACIONES','N:M usuario-vacante: hoja de evaluación de un evaluador.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('usuario','LONG','Long',True,'Usuario evaluado'),
 C('vacante','LONG','Long',True,'Vacante contra la que se evalúa'),
 C('evaluador','LONG','Long',True,'Quién evalúa'),
 C('fecha','DATETIME','DateTime',True,'Fecha de la evaluación',defecto='Date()'),
 C('d1_match_cv','LONG','Long',True,'Encaje de habilidades y experiencia con la vacante, 1 a 5','Between 1 And 5','Entre 1 y 5'),
 C('d2_north_star','LONG','Long',True,'Encaje con el tipo de puesto que busca el usuario, 1 a 5','Between 1 And 5','Entre 1 y 5'),
 C('d3_compensacion','LONG','Long',True,'Salario frente al mercado, 1 a 5','Between 1 And 5','Entre 1 y 5'),
 C('d4_cultura','LONG','Long',True,'Cultura, estabilidad y teletrabajo, 1 a 5','Between 1 And 5','Entre 1 y 5'),
 C('d5_red_flags','LONG','Long',True,'Alertas y bloqueos, 1 a 5 (5 = sin alertas)','Between 1 And 5','Entre 1 y 5'),
 C('global','SINGLE','Single',True,'Puntuación holística 1 a 5; va al certificado (x20 = %)','Between 1 And 5','Entre 1 y 5'),
 C('global_personal','SINGLE','Single',False,'Reordenación por los pesos del usuario','Between 1 And 5','Entre 1 y 5'),
 C('banda','TEXT(6)','Text Width 6',True,'Alta (>=4), Media (3-3,9) o Baja (<3)',IN('Alta','Media','Baja'),'Banda: Alta, Media o Baja'),
 C('explicacion','MEMO','Memo',False,'Tres líneas de explicación'),
 C('hueco','MEMO','Memo',False,'Qué le falta para subir un punto'),
 C('hash_cv','TEXT(32)','Text Width 32',True,'Huella del CV evaluado (caché)'),
],['CONSTRAINT pk_evaluaciones PRIMARY KEY (id)',
  'CONSTRAINT fk_evaluaciones_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id)',
  'CONSTRAINT fk_evaluaciones_vacante FOREIGN KEY (vacante) REFERENCES VACANTES (id)',
  'CONSTRAINT fk_evaluaciones_evaluador FOREIGN KEY (evaluador) REFERENCES EVALUADORES (id)'],
 ['CREATE UNIQUE INDEX uq_evaluaciones ON EVALUACIONES (usuario, vacante, evaluador, hash_cv)']))
T.append(('FEEDBACK','N:M usuario-vacante: qué hace el usuario con cada vacante.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('usuario','LONG','Long',True,'Usuario'),
 C('vacante','LONG','Long',True,'Vacante'),
 C('veredicto','TEXT(22)','Text Width 22',True,'Qué decidió o qué pasó',IN('descartada','guardada','postulada','entrevista','oferta','descartada_por_empresa'),'Veredicto no admitido'),
 C('motivo','TEXT(30)','Text Width 30',False,'Solo si la descarta',IN('sector','salario','lejos','tarea','empresa','otro'),'Motivo: sector, salario, lejos, tarea, empresa u otro'),
 C('fecha','DATETIME','DateTime',True,'Fecha',defecto='Date()'),
],['CONSTRAINT pk_feedback PRIMARY KEY (id)',
  'CONSTRAINT fk_feedback_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id)',
  'CONSTRAINT fk_feedback_vacante FOREIGN KEY (vacante) REFERENCES VACANTES (id)'],[]))
T.append(('CERTIFICADOS','Certificado de congruencia para una vacante; nace de una evaluación.',[
 C('id','COUNTER','Long',True,'Identificador'),
 C('usuario','LONG','Long',True,'Titular'),
 C('vacante','LONG','Long',True,'Vacante objetivo'),
 C('evaluacion','LONG','Long',True,'Evaluación de la que nace'),
 C('codigo','TEXT(36)','Text Width 36',True,'UUID; va en la URL de verificación'),
 C('firma','TEXT(64)','Text Width 64',True,'HMAC-SHA256 de codigo|usuario|vacante|global|fecha'),
 C('fecha_emision','DATETIME','DateTime',True,'Fecha de emisión',defecto='Date()'),
 C('fecha_caducidad','DATETIME','DateTime',True,'Emisión + 30 días'),
 C('estado','TEXT(10)','Text Width 10',True,'vigente, caducado o revocado',IN('vigente','caducado','revocado'),'Estado: vigente, caducado o revocado','"vigente"'),
 C('veces_verificado','LONG','Long',False,'Veces que una empresa lo comprobó','>=0','No puede ser negativo','0'),
],['CONSTRAINT pk_certificados PRIMARY KEY (id)','CONSTRAINT uq_certificados_codigo UNIQUE (codigo)',
  'CONSTRAINT fk_certificados_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id)',
  'CONSTRAINT fk_certificados_vacante FOREIGN KEY (vacante) REFERENCES VACANTES (id)',
  'CONSTRAINT fk_certificados_evaluacion FOREIGN KEY (evaluacion) REFERENCES EVALUACIONES (id)'],[]))
ORDEN=[t[0] for t in T]
COLS={t[0]:[c['col'] for c in t[2]] for t in T}
