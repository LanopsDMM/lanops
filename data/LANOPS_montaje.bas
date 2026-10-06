Attribute VB_Name = "LANOPS_montaje"
Option Compare Database
Option Explicit

' LANOPS - montaje del .mdb (generado desde esquema.py; no editar a mano, regenerar)
' Paso1_CrearTablas: 13 tablas con tipos, claves, indices, reglas, descripciones y las 15 relaciones con integridad
' Paso2_ImportarCSV: carga los CSV de la carpeta lanops_csv (junto al .mdb) en orden padres -> hijas
' Paso3_Probar: prueba de integridad (usuario 9999), regla de validacion e indice sin duplicados; deshace todo

Private Const CARPETA As String = "lanops_csv"

Private Function Tablas() As Variant
    Tablas = Array("CONFIGURACION", "ENTIDADES", "HABILIDADES", "EVALUADORES", "EMPRESAS", "USUARIOS", "VERIFICACIONES", "VACANTES", "USUARIO_HABILIDAD", "PREFERENCIAS", "EVALUACIONES", "FEEDBACK", "CERTIFICADOS")
End Function

Private Sub X(db As DAO.Database, ByVal sql As String)
    On Error GoTo fallo
    db.Execute sql, dbFailOnError
    Exit Sub
fallo:
    Debug.Print sql
    Err.Raise Err.Number, "LANOPS", Err.Description & vbCrLf & vbCrLf & Left(sql, 300)
End Sub

Private Sub SetProp(obj As Object, ByVal nombre As String, ByVal tipo As Integer, ByVal valor As Variant)
    On Error Resume Next
    obj.Properties(nombre) = valor
    If Err.Number <> 0 Then
        Err.Clear
        obj.Properties.Append obj.CreateProperty(nombre, tipo, valor)
    End If
    On Error GoTo 0
End Sub

Private Sub Campo(db As DAO.Database, ByVal t As String, ByVal c As String, ByVal desc As String, ByVal regla As String, ByVal txt As String, ByVal defecto As String)
    Dim fld As DAO.Field
    Set fld = db.TableDefs(t).Fields(c)
    SetProp fld, "Description", dbText, desc
    If regla <> "" Then fld.ValidationRule = regla: fld.ValidationText = txt
    If defecto <> "" Then fld.DefaultValue = defecto
    Select Case fld.Type
        Case dbBoolean: SetProp fld, "DisplayControl", dbInteger, 106: SetProp fld, "Format", dbText, "Yes/No"
        Case dbDate: SetProp fld, "Format", dbText, "Short Date"
        Case dbSingle: SetProp fld, "Format", dbText, "Fixed": SetProp fld, "DecimalPlaces", dbByte, 1
    End Select
End Sub

Private Function Existe(db As DAO.Database, ByVal t As String) As Boolean
    Dim td As DAO.TableDef
    For Each td In db.TableDefs
        If td.Name = t Then Existe = True: Exit Function
    Next
End Function

Private Function EsNuestra(ByVal t As String) As Boolean
    Dim x As Variant
    For Each x In Tablas()
        If x = t Then EsNuestra = True: Exit Function
    Next
End Function

Public Sub Paso0_BorrarTablas()
    Dim db As DAO.Database, i As Integer, hay As Boolean, t As Variant
    Set db = CurrentDb
    For Each t In Tablas()
        If Existe(db, CStr(t)) Then hay = True
    Next
    If Existe(db, "tmp_usuarios") Then db.Execute "DROP TABLE tmp_usuarios"
    If Not hay Then Exit Sub
    If MsgBox("Se borraran las tablas de LANOPS y sus datos. ¿Seguir?", vbYesNo + vbExclamation, "LANOPS") = vbNo Then End
    For i = db.Relations.Count - 1 To 0 Step -1
        If EsNuestra(db.Relations(i).Table) Or EsNuestra(db.Relations(i).ForeignTable) Then db.Relations.Delete db.Relations(i).Name
    Next
    For i = UBound(Tablas()) To 0 Step -1
        If Existe(db, Tablas()(i)) Then db.Execute "DROP TABLE [" & Tablas()(i) & "]"
    Next
    db.TableDefs.Refresh
End Sub

Public Sub Paso1_CrearTablas()
    Dim db As DAO.Database, s As String
    Paso0_BorrarTablas
    Set db = CurrentDb
    ' ---- CONFIGURACION
    s = "CREATE TABLE [CONFIGURACION] ("
    s = s & "[clave] TEXT(40) NOT NULL, "
    s = s & "[valor] TEXT(100) NOT NULL, "
    s = s & "[descripcion] TEXT(150), "
    s = s & "CONSTRAINT pk_configuracion PRIMARY KEY (clave))"
    X db, s
    ' ---- ENTIDADES
    s = "CREATE TABLE [ENTIDADES] ("
    s = s & "[id] COUNTER, "
    s = s & "[nombre] TEXT(100) NOT NULL, "
    s = s & "[tipo] TEXT(15) NOT NULL, "
    s = s & "[dominio_email] TEXT(60), "
    s = s & "[contacto] TEXT(150), "
    s = s & "[activa] YESNO, "
    s = s & "CONSTRAINT pk_entidades PRIMARY KEY (id), "
    s = s & "CONSTRAINT uq_entidades_nombre UNIQUE (nombre))"
    X db, s
    ' ---- HABILIDADES
    s = "CREATE TABLE [HABILIDADES] ("
    s = s & "[id] COUNTER, "
    s = s & "[nombre] TEXT(60) NOT NULL, "
    s = s & "[categoria] TEXT(40) NOT NULL, "
    s = s & "CONSTRAINT pk_habilidades PRIMARY KEY (id), "
    s = s & "CONSTRAINT uq_habilidades_nombre UNIQUE (nombre))"
    X db, s
    ' ---- EVALUADORES
    s = "CREATE TABLE [EVALUADORES] ("
    s = s & "[id] COUNTER, "
    s = s & "[nombre] TEXT(60) NOT NULL, "
    s = s & "[tipo] TEXT(10) NOT NULL, "
    s = s & "[version_rubrica] TEXT(30) NOT NULL, "
    s = s & "[modelo] TEXT(60), "
    s = s & "[prompt] MEMO, "
    s = s & "[activo] YESNO, "
    s = s & "[fecha_alta] DATETIME, "
    s = s & "CONSTRAINT pk_evaluadores PRIMARY KEY (id))"
    X db, s
    ' ---- EMPRESAS
    s = "CREATE TABLE [EMPRESAS] ("
    s = s & "[id] COUNTER, "
    s = s & "[nombre] TEXT(100) NOT NULL, "
    s = s & "[sector] TEXT(60), "
    s = s & "[ciudad] TEXT(60), "
    s = s & "[anillo] LONG NOT NULL, "
    s = s & "[tamano] TEXT(20), "
    s = s & "[url_web] TEXT(255), "
    s = s & "[url_empleo] TEXT(255), "
    s = s & "[tipo_lectura] TEXT(10), "
    s = s & "[ultima_lectura] DATETIME, "
    s = s & "[fallos_seguidos] LONG, "
    s = s & "[activa] YESNO, "
    s = s & "CONSTRAINT pk_empresas PRIMARY KEY (id))"
    X db, s
    ' ---- USUARIOS
    s = "CREATE TABLE [USUARIOS] ("
    s = s & "[id] COUNTER, "
    s = s & "[nombre] TEXT(100) NOT NULL, "
    s = s & "[email] TEXT(150) NOT NULL, "
    s = s & "[ciudad] TEXT(60), "
    s = s & "[titulacion] TEXT(100), "
    s = s & "[estado_verificacion] TEXT(15) NOT NULL, "
    s = s & "[recomendado_por] LONG, "
    s = s & "[visibilidad] YESNO, "
    s = s & "[fecha_alta] DATETIME NOT NULL, "
    s = s & "[consentimiento_fecha] DATETIME, "
    s = s & "[cv_texto] MEMO, "
    s = s & "CONSTRAINT pk_usuarios PRIMARY KEY (id), "
    s = s & "CONSTRAINT uq_usuarios_email UNIQUE (email))"
    X db, s
    X db, "ALTER TABLE USUARIOS ADD CONSTRAINT fk_usuarios_recomendado FOREIGN KEY (recomendado_por) REFERENCES USUARIOS (id)"
    ' ---- VERIFICACIONES
    s = "CREATE TABLE [VERIFICACIONES] ("
    s = s & "[id] COUNTER, "
    s = s & "[usuario] LONG NOT NULL, "
    s = s & "[entidad] LONG NOT NULL, "
    s = s & "[tipo] TEXT(20) NOT NULL, "
    s = s & "[fecha] DATETIME NOT NULL, "
    s = s & "[estado] TEXT(12) NOT NULL, "
    s = s & "[verificado_por] TEXT(60), "
    s = s & "CONSTRAINT pk_verificaciones PRIMARY KEY (id), "
    s = s & "CONSTRAINT fk_verificaciones_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id), "
    s = s & "CONSTRAINT fk_verificaciones_entidad FOREIGN KEY (entidad) REFERENCES ENTIDADES (id))"
    X db, s
    ' ---- VACANTES
    s = "CREATE TABLE [VACANTES] ("
    s = s & "[id] COUNTER, "
    s = s & "[empresa] LONG NOT NULL, "
    s = s & "[puesto] TEXT(150) NOT NULL, "
    s = s & "[requisitos] MEMO, "
    s = s & "[contrato] TEXT(30), "
    s = s & "[jornada] TEXT(20), "
    s = s & "[ubicacion] TEXT(60), "
    s = s & "[salario_min] LONG, "
    s = s & "[estado] TEXT(10) NOT NULL, "
    s = s & "[fuente] TEXT(10) NOT NULL, "
    s = s & "[url_origen] TEXT(255), "
    s = s & "[codigo_externo] TEXT(30), "
    s = s & "[hash] TEXT(32) NOT NULL, "
    s = s & "[fecha_pub] DATETIME, "
    s = s & "[vista_en] DATETIME, "
    s = s & "CONSTRAINT pk_vacantes PRIMARY KEY (id), "
    s = s & "CONSTRAINT uq_vacantes_hash UNIQUE (hash), "
    s = s & "CONSTRAINT fk_vacantes_empresa FOREIGN KEY (empresa) REFERENCES EMPRESAS (id))"
    X db, s
    ' ---- USUARIO_HABILIDAD
    s = "CREATE TABLE [USUARIO_HABILIDAD] ("
    s = s & "[usuario] LONG NOT NULL, "
    s = s & "[habilidad] LONG NOT NULL, "
    s = s & "[nivel] LONG NOT NULL, "
    s = s & "CONSTRAINT pk_usuario_habilidad PRIMARY KEY (usuario, habilidad), "
    s = s & "CONSTRAINT fk_uh_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id), "
    s = s & "CONSTRAINT fk_uh_habilidad FOREIGN KEY (habilidad) REFERENCES HABILIDADES (id))"
    X db, s
    ' ---- PREFERENCIAS
    s = "CREATE TABLE [PREFERENCIAS] ("
    s = s & "[id] COUNTER, "
    s = s & "[usuario] LONG NOT NULL, "
    s = s & "[tipo] TEXT(10) NOT NULL, "
    s = s & "[clave] TEXT(40) NOT NULL, "
    s = s & "[valor] TEXT(60) NOT NULL, "
    s = s & "[peso] LONG, "
    s = s & "[fecha_mod] DATETIME, "
    s = s & "CONSTRAINT pk_preferencias PRIMARY KEY (id), "
    s = s & "CONSTRAINT fk_preferencias_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id))"
    X db, s
    X db, "CREATE UNIQUE INDEX uq_preferencias ON PREFERENCIAS (usuario, tipo, clave, valor)"
    ' ---- EVALUACIONES
    s = "CREATE TABLE [EVALUACIONES] ("
    s = s & "[id] COUNTER, "
    s = s & "[usuario] LONG NOT NULL, "
    s = s & "[vacante] LONG NOT NULL, "
    s = s & "[evaluador] LONG NOT NULL, "
    s = s & "[fecha] DATETIME NOT NULL, "
    s = s & "[d1_match_cv] LONG NOT NULL, "
    s = s & "[d2_north_star] LONG NOT NULL, "
    s = s & "[d3_compensacion] LONG NOT NULL, "
    s = s & "[d4_cultura] LONG NOT NULL, "
    s = s & "[d5_red_flags] LONG NOT NULL, "
    s = s & "[global] SINGLE NOT NULL, "
    s = s & "[global_personal] SINGLE, "
    s = s & "[banda] TEXT(6) NOT NULL, "
    s = s & "[explicacion] MEMO, "
    s = s & "[hueco] MEMO, "
    s = s & "[hash_cv] TEXT(32) NOT NULL, "
    s = s & "CONSTRAINT pk_evaluaciones PRIMARY KEY (id), "
    s = s & "CONSTRAINT fk_evaluaciones_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id), "
    s = s & "CONSTRAINT fk_evaluaciones_vacante FOREIGN KEY (vacante) REFERENCES VACANTES (id), "
    s = s & "CONSTRAINT fk_evaluaciones_evaluador FOREIGN KEY (evaluador) REFERENCES EVALUADORES (id))"
    X db, s
    X db, "CREATE UNIQUE INDEX uq_evaluaciones ON EVALUACIONES (usuario, vacante, evaluador, hash_cv)"
    ' ---- FEEDBACK
    s = "CREATE TABLE [FEEDBACK] ("
    s = s & "[id] COUNTER, "
    s = s & "[usuario] LONG NOT NULL, "
    s = s & "[vacante] LONG NOT NULL, "
    s = s & "[veredicto] TEXT(22) NOT NULL, "
    s = s & "[motivo] TEXT(30), "
    s = s & "[fecha] DATETIME NOT NULL, "
    s = s & "CONSTRAINT pk_feedback PRIMARY KEY (id), "
    s = s & "CONSTRAINT fk_feedback_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id), "
    s = s & "CONSTRAINT fk_feedback_vacante FOREIGN KEY (vacante) REFERENCES VACANTES (id))"
    X db, s
    ' ---- CERTIFICADOS
    s = "CREATE TABLE [CERTIFICADOS] ("
    s = s & "[id] COUNTER, "
    s = s & "[usuario] LONG NOT NULL, "
    s = s & "[vacante] LONG NOT NULL, "
    s = s & "[evaluacion] LONG NOT NULL, "
    s = s & "[codigo] TEXT(36) NOT NULL, "
    s = s & "[firma] TEXT(64) NOT NULL, "
    s = s & "[fecha_emision] DATETIME NOT NULL, "
    s = s & "[fecha_caducidad] DATETIME NOT NULL, "
    s = s & "[estado] TEXT(10) NOT NULL, "
    s = s & "[veces_verificado] LONG, "
    s = s & "CONSTRAINT pk_certificados PRIMARY KEY (id), "
    s = s & "CONSTRAINT uq_certificados_codigo UNIQUE (codigo), "
    s = s & "CONSTRAINT fk_certificados_usuario FOREIGN KEY (usuario) REFERENCES USUARIOS (id), "
    s = s & "CONSTRAINT fk_certificados_vacante FOREIGN KEY (vacante) REFERENCES VACANTES (id), "
    s = s & "CONSTRAINT fk_certificados_evaluacion FOREIGN KEY (evaluacion) REFERENCES EVALUACIONES (id))"
    X db, s
    db.TableDefs.Refresh
    SetProp db.TableDefs("CONFIGURACION"), "Description", dbText, "Parámetros de negocio (cupo, caducidad, umbrales). Ningún número de negocio vive en los flujos."
    Campo db, "CONFIGURACION", "clave", "Nombre del parámetro", "", "", ""
    Campo db, "CONFIGURACION", "valor", "Valor del parámetro", "", "", ""
    Campo db, "CONFIGURACION", "descripcion", "Para qué sirve", "", "", ""
    SetProp db.TableDefs("ENTIDADES"), "Description", dbText, "Entidades que pueden verificar a un usuario (universidad, entidad social, servicio público)."
    Campo db, "ENTIDADES", "id", "Identificador", "", "", ""
    Campo db, "ENTIDADES", "nombre", "Nombre de la entidad", "", "", ""
    Campo db, "ENTIDADES", "tipo", "universidad, social o publica", "In (""universidad"",""social"",""publica"")", "Tipo: universidad, social o publica", ""
    Campo db, "ENTIDADES", "dominio_email", "Dominio de correo para la verificación automática", "", "", ""
    Campo db, "ENTIDADES", "contacto", "Persona o correo de contacto", "", "", ""
    Campo db, "ENTIDADES", "activa", "Si puede verificar hoy", "", "", "-1"
    SetProp db.TableDefs("HABILIDADES"), "Description", dbText, "Catálogo común de habilidades: base de los filtros finos."
    Campo db, "HABILIDADES", "id", "Identificador", "", "", ""
    Campo db, "HABILIDADES", "nombre", "Nombre de la habilidad", "", "", ""
    Campo db, "HABILIDADES", "categoria", "tecnica, idioma, transversal o herramienta", "In (""tecnica"",""idioma"",""transversal"",""herramienta"")", "Categoría: tecnica, idioma, transversal o herramienta", ""
    SetProp db.TableDefs("EVALUADORES"), "Description", dbText, "Quién rellena una evaluación: una versión del motor de IA o una persona."
    Campo db, "EVALUADORES", "id", "Identificador", "", "", ""
    Campo db, "EVALUADORES", "nombre", "Nombre del evaluador", "", "", ""
    Campo db, "EVALUADORES", "tipo", "ia o humano", "In (""ia"",""humano"")", "Tipo: ia o humano", ""
    Campo db, "EVALUADORES", "version_rubrica", "Versión de la rúbrica que aplica", "", "", ""
    Campo db, "EVALUADORES", "modelo", "Modelo de IA; vacío si es humano", "", "", ""
    Campo db, "EVALUADORES", "prompt", "Instrucciones vigentes del evaluador", "", "", ""
    Campo db, "EVALUADORES", "activo", "Solo un evaluador de IA activo a la vez", "", "", "-1"
    Campo db, "EVALUADORES", "fecha_alta", "Desde cuándo evalúa", "", "", ""
    SetProp db.TableDefs("EMPRESAS"), "Description", dbText, "Empresas que publican vacantes. anillo 1 = Gipuzkoa."
    Campo db, "EMPRESAS", "id", "Identificador", "", "", ""
    Campo db, "EMPRESAS", "nombre", "Razón comercial", "", "", ""
    Campo db, "EMPRESAS", "sector", "Sector de actividad", "", "", ""
    Campo db, "EMPRESAS", "ciudad", "Municipio de la sede", "", "", ""
    Campo db, "EMPRESAS", "anillo", "1 Gipuzkoa, 2 Madrid, 3 resto", "Between 1 And 3", "Anillo: 1, 2 o 3", "1"
    Campo db, "EMPRESAS", "tamano", "micro, pequeña, mediana o grande", "In (""micro"",""pequeña"",""mediana"",""grande"")", "Tamaño: micro, pequeña, mediana o grande", ""
    Campo db, "EMPRESAS", "url_web", "Web corporativa", "", "", ""
    Campo db, "EMPRESAS", "url_empleo", "Página de empleo que lee el agente", "", "", ""
    Campo db, "EMPRESAS", "tipo_lectura", "Cómo se leen sus vacantes", "In (""jsonld"",""html"",""ats"",""pdf"",""manual"",""ninguna"")", "Lectura: jsonld, html, ats, pdf, manual o ninguna", ""
    Campo db, "EMPRESAS", "ultima_lectura", "Última lectura del agente", "", "", ""
    Campo db, "EMPRESAS", "fallos_seguidos", "Lecturas fallidas seguidas; alerta con 2 o más", ">=0", "No puede ser negativo", "0"
    Campo db, "EMPRESAS", "activa", "Si se sigue leyendo", "", "", "-1"
    SetProp db.TableDefs("USUARIOS"), "Description", dbText, "Personas que buscan empleo. Entrada abierta; la verificación es opcional."
    Campo db, "USUARIOS", "id", "Identificador", "", "", ""
    Campo db, "USUARIOS", "nombre", "Nombre y apellidos", "", "", ""
    Campo db, "USUARIOS", "email", "Correo; único", "", "", ""
    Campo db, "USUARIOS", "ciudad", "Municipio de residencia", "", "", ""
    Campo db, "USUARIOS", "titulacion", "Titulación; vacío si no tiene", "", "", ""
    Campo db, "USUARIOS", "estado_verificacion", "sin_verificar, pendiente, verificado o revocado", "In (""sin_verificar"",""pendiente"",""verificado"",""revocado"")", "Estado: sin_verificar, pendiente, verificado o revocado", """sin_verificar"""
    Campo db, "USUARIOS", "recomendado_por", "Usuario que lo recomendó (autorreferencia)", "", "", ""
    Campo db, "USUARIOS", "visibilidad", "Si su perfil es visible en la red", "", "", "-1"
    Campo db, "USUARIOS", "fecha_alta", "Fecha de registro", "", "", "Date()"
    Campo db, "USUARIOS", "consentimiento_fecha", "Fecha del consentimiento RGPD", "", "", ""
    Campo db, "USUARIOS", "cv_texto", "Texto del currículum (sin DNI, fecha de nacimiento ni dirección)", "", "", ""
    SetProp db.TableDefs("VERIFICACIONES"), "Description", dbText, "Cada vez que una entidad comprueba a un usuario."
    Campo db, "VERIFICACIONES", "id", "Identificador", "", "", ""
    Campo db, "VERIFICACIONES", "usuario", "Usuario verificado", "", "", ""
    Campo db, "VERIFICACIONES", "entidad", "Entidad que verifica", "", "", ""
    Campo db, "VERIFICACIONES", "tipo", "email_institucional, documental o aval", "In (""email_institucional"",""documental"",""aval"")", "Tipo: email_institucional, documental o aval", ""
    Campo db, "VERIFICACIONES", "fecha", "Fecha de la verificación", "", "", "Date()"
    Campo db, "VERIFICACIONES", "estado", "pendiente, aprobada, rechazada o revocada", "In (""pendiente"",""aprobada"",""rechazada"",""revocada"")", "Estado: pendiente, aprobada, rechazada o revocada", """pendiente"""
    Campo db, "VERIFICACIONES", "verificado_por", "Quién la aprobó o sistema", "", "", ""
    SetProp db.TableDefs("VACANTES"), "Description", dbText, "Ofertas de empleo, vengan de donde vengan."
    Campo db, "VACANTES", "id", "Identificador", "", "", ""
    Campo db, "VACANTES", "empresa", "Empresa que la publica", "", "", ""
    Campo db, "VACANTES", "puesto", "Título del puesto", "", "", ""
    Campo db, "VACANTES", "requisitos", "Requisitos tal como se publicaron", "", "", ""
    Campo db, "VACANTES", "contrato", "indefinido, temporal, practicas u otro", "In (""indefinido"",""temporal"",""practicas"",""otro"")", "Contrato: indefinido, temporal, practicas u otro", ""
    Campo db, "VACANTES", "jornada", "completa, parcial o indiferente", "In (""completa"",""parcial"",""indiferente"")", "Jornada: completa, parcial o indiferente", ""
    Campo db, "VACANTES", "ubicacion", "Municipio del puesto", "", "", ""
    Campo db, "VACANTES", "salario_min", "Euros brutos al año; vacío si no consta", ">=0", "No puede ser negativo", ""
    Campo db, "VACANTES", "estado", "abierta o cerrada", "In (""abierta"",""cerrada"")", "Estado: abierta o cerrada", """abierta"""
    Campo db, "VACANTES", "fuente", "usuario, lanbide, api, agente o manual", "In (""usuario"",""lanbide"",""api"",""agente"",""manual"")", "Fuente: usuario, lanbide, api, agente o manual", ""
    Campo db, "VACANTES", "url_origen", "Dónde se publicó", "", "", ""
    Campo db, "VACANTES", "codigo_externo", "Código de Lanbide o del ATS", "", "", ""
    Campo db, "VACANTES", "hash", "Huella para no duplicar la vacante", "", "", ""
    Campo db, "VACANTES", "fecha_pub", "Fecha de publicación", "", "", ""
    Campo db, "VACANTES", "vista_en", "Última vez que se vio publicada", "", "", ""
    SetProp db.TableDefs("USUARIO_HABILIDAD"), "Description", dbText, "N:M usuario-habilidad con nivel."
    Campo db, "USUARIO_HABILIDAD", "usuario", "Usuario", "", "", ""
    Campo db, "USUARIO_HABILIDAD", "habilidad", "Habilidad del catálogo", "", "", ""
    Campo db, "USUARIO_HABILIDAD", "nivel", "Nivel de 1 a 5", "Between 1 And 5", "Nivel entre 1 y 5", ""
    SetProp db.TableDefs("PREFERENCIAS"), "Description", dbText, "Perfil de búsqueda: qué no negocia (duro), qué prefiere con peso y qué excluye."
    Campo db, "PREFERENCIAS", "id", "Identificador", "", "", ""
    Campo db, "PREFERENCIAS", "usuario", "Usuario", "", "", ""
    Campo db, "PREFERENCIAS", "tipo", "duro, peso o exclusion", "In (""duro"",""peso"",""exclusion"")", "Tipo: duro, peso o exclusion", ""
    Campo db, "PREFERENCIAS", "clave", "Qué se filtra u ordena", "In (""municipio"",""radio_km"",""jornada"",""contrato"",""salario_min"",""modalidad"",""fecha_inicio_max"",""permiso_trabajo"",""euskera"",""sector"",""tamano"",""idioma"",""estabilidad"",""ett"",""palabra"",""empresa"",""movilidad"",""turnos"",""puesto_objetivo"",""situacion_actual"")", "Clave no admitida", ""
    Campo db, "PREFERENCIAS", "valor", "Valor de la preferencia", "", "", ""
    Campo db, "PREFERENCIAS", "peso", "1 a 5 si tipo = peso", "Between 1 And 5", "Peso entre 1 y 5", ""
    Campo db, "PREFERENCIAS", "fecha_mod", "Última modificación", "", "", "Date()"
    SetProp db.TableDefs("EVALUACIONES"), "Description", dbText, "N:M usuario-vacante: hoja de evaluación de un evaluador."
    Campo db, "EVALUACIONES", "id", "Identificador", "", "", ""
    Campo db, "EVALUACIONES", "usuario", "Usuario evaluado", "", "", ""
    Campo db, "EVALUACIONES", "vacante", "Vacante contra la que se evalúa", "", "", ""
    Campo db, "EVALUACIONES", "evaluador", "Quién evalúa", "", "", ""
    Campo db, "EVALUACIONES", "fecha", "Fecha de la evaluación", "", "", "Date()"
    Campo db, "EVALUACIONES", "d1_match_cv", "Encaje de habilidades y experiencia con la vacante, 1 a 5", "Between 1 And 5", "Entre 1 y 5", ""
    Campo db, "EVALUACIONES", "d2_north_star", "Encaje con el tipo de puesto que busca el usuario, 1 a 5", "Between 1 And 5", "Entre 1 y 5", ""
    Campo db, "EVALUACIONES", "d3_compensacion", "Salario frente al mercado, 1 a 5", "Between 1 And 5", "Entre 1 y 5", ""
    Campo db, "EVALUACIONES", "d4_cultura", "Cultura, estabilidad y teletrabajo, 1 a 5", "Between 1 And 5", "Entre 1 y 5", ""
    Campo db, "EVALUACIONES", "d5_red_flags", "Alertas y bloqueos, 1 a 5 (5 = sin alertas)", "Between 1 And 5", "Entre 1 y 5", ""
    Campo db, "EVALUACIONES", "global", "Puntuación holística 1 a 5; va al certificado (x20 = %)", "Between 1 And 5", "Entre 1 y 5", ""
    Campo db, "EVALUACIONES", "global_personal", "Reordenación por los pesos del usuario", "Between 1 And 5", "Entre 1 y 5", ""
    Campo db, "EVALUACIONES", "banda", "Alta (>=4), Media (3-3,9) o Baja (<3)", "In (""Alta"",""Media"",""Baja"")", "Banda: Alta, Media o Baja", ""
    Campo db, "EVALUACIONES", "explicacion", "Tres líneas de explicación", "", "", ""
    Campo db, "EVALUACIONES", "hueco", "Qué le falta para subir un punto", "", "", ""
    Campo db, "EVALUACIONES", "hash_cv", "Huella del CV evaluado (caché)", "", "", ""
    SetProp db.TableDefs("FEEDBACK"), "Description", dbText, "N:M usuario-vacante: qué hace el usuario con cada vacante."
    Campo db, "FEEDBACK", "id", "Identificador", "", "", ""
    Campo db, "FEEDBACK", "usuario", "Usuario", "", "", ""
    Campo db, "FEEDBACK", "vacante", "Vacante", "", "", ""
    Campo db, "FEEDBACK", "veredicto", "Qué decidió o qué pasó", "In (""descartada"",""guardada"",""postulada"",""entrevista"",""oferta"",""descartada_por_empresa"")", "Veredicto no admitido", ""
    Campo db, "FEEDBACK", "motivo", "Solo si la descarta", "In (""sector"",""salario"",""lejos"",""tarea"",""empresa"",""otro"")", "Motivo: sector, salario, lejos, tarea, empresa u otro", ""
    Campo db, "FEEDBACK", "fecha", "Fecha", "", "", "Date()"
    SetProp db.TableDefs("CERTIFICADOS"), "Description", dbText, "Certificado de congruencia para una vacante; nace de una evaluación."
    Campo db, "CERTIFICADOS", "id", "Identificador", "", "", ""
    Campo db, "CERTIFICADOS", "usuario", "Titular", "", "", ""
    Campo db, "CERTIFICADOS", "vacante", "Vacante objetivo", "", "", ""
    Campo db, "CERTIFICADOS", "evaluacion", "Evaluación de la que nace", "", "", ""
    Campo db, "CERTIFICADOS", "codigo", "UUID; va en la URL de verificación", "", "", ""
    Campo db, "CERTIFICADOS", "firma", "HMAC-SHA256 de codigo|usuario|vacante|global|fecha", "", "", ""
    Campo db, "CERTIFICADOS", "fecha_emision", "Fecha de emisión", "", "", "Date()"
    Campo db, "CERTIFICADOS", "fecha_caducidad", "Emisión + 30 días", "", "", ""
    Campo db, "CERTIFICADOS", "estado", "vigente, caducado o revocado", "In (""vigente"",""caducado"",""revocado"")", "Estado: vigente, caducado o revocado", """vigente"""
    Campo db, "CERTIFICADOS", "veces_verificado", "Veces que una empresa lo comprobó", ">=0", "No puede ser negativo", "0"
    MsgBox "Paso 1 hecho: 13 tablas y " & Relaciones(db) & " relaciones con integridad referencial (esperadas: 15).", vbInformation, "LANOPS"
End Sub

Private Function Relaciones(db As DAO.Database) As Integer
    Dim r As DAO.Relation
    For Each r In db.Relations
        If EsNuestra(r.Table) And EsNuestra(r.ForeignTable) Then Relaciones = Relaciones + 1
    Next
End Function

Public Sub Paso2_ImportarCSV()
    Dim db As DAO.Database, ruta As String, src As String, t As Variant, i As Integer, msg As String
    Set db = CurrentDb
    ruta = CurrentProject.Path & "\" & CARPETA
    If Dir(ruta & "\schema.ini") = "" Then MsgBox "No encuentro " & ruta & "\schema.ini. Descomprime lanops_csv junto a " & CurrentProject.Name, vbCritical, "LANOPS": Exit Sub
    src = "[Text;DATABASE=" & ruta & ";HDR=Yes]."
    ' vaciar si ya hay datos (hijas primero)
    For i = UBound(Tablas()) To 0 Step -1
        db.Execute "DELETE FROM [" & Tablas()(i) & "]", dbFailOnError
    Next
    If Existe(db, "tmp_usuarios") Then db.Execute "DROP TABLE tmp_usuarios"
    X db, "INSERT INTO [CONFIGURACION] ([clave], [valor], [descripcion]) SELECT [clave], [valor], [descripcion] FROM " & src & "[CONFIGURACION#csv]"
    X db, "INSERT INTO [ENTIDADES] ([id], [nombre], [tipo], [dominio_email], [contacto], [activa]) SELECT [id], [nombre], [tipo], [dominio_email], [contacto], [activa] FROM " & src & "[ENTIDADES#csv]"
    X db, "INSERT INTO [HABILIDADES] ([id], [nombre], [categoria]) SELECT [id], [nombre], [categoria] FROM " & src & "[HABILIDADES#csv]"
    X db, "INSERT INTO [EVALUADORES] ([id], [nombre], [tipo], [version_rubrica], [modelo], [prompt], [activo], [fecha_alta]) SELECT [id], [nombre], [tipo], [version_rubrica], [modelo], [prompt], [activo], [fecha_alta] FROM " & src & "[EVALUADORES#csv]"
    X db, "INSERT INTO [EMPRESAS] ([id], [nombre], [sector], [ciudad], [anillo], [tamano], [url_web], [url_empleo], [tipo_lectura], [ultima_lectura], [fallos_seguidos], [activa]) SELECT [id], [nombre], [sector], [ciudad], [anillo], [tamano], [url_web], [url_empleo], [tipo_lectura], [ultima_lectura], [fallos_seguidos], [activa] FROM " & src & "[EMPRESAS#csv]"
    X db, "SELECT * INTO tmp_usuarios FROM " & src & "[USUARIOS#csv]"
    X db, "INSERT INTO [USUARIOS] ([id], [nombre], [email], [ciudad], [titulacion], [estado_verificacion], [visibilidad], [fecha_alta], [consentimiento_fecha], [cv_texto]) SELECT [id], [nombre], [email], [ciudad], [titulacion], [estado_verificacion], [visibilidad], [fecha_alta], [consentimiento_fecha], [cv_texto] FROM tmp_usuarios ORDER BY [id]"
    X db, "UPDATE [USUARIOS] INNER JOIN tmp_usuarios ON [USUARIOS].[id] = tmp_usuarios.[id] SET [USUARIOS].[recomendado_por] = tmp_usuarios.[recomendado_por] WHERE tmp_usuarios.[recomendado_por] Is Not Null"
    X db, "DROP TABLE tmp_usuarios"
    X db, "INSERT INTO [VERIFICACIONES] ([id], [usuario], [entidad], [tipo], [fecha], [estado], [verificado_por]) SELECT [id], [usuario], [entidad], [tipo], [fecha], [estado], [verificado_por] FROM " & src & "[VERIFICACIONES#csv]"
    X db, "INSERT INTO [VACANTES] ([id], [empresa], [puesto], [requisitos], [contrato], [jornada], [ubicacion], [salario_min], [estado], [fuente], [url_origen], [codigo_externo], [hash], [fecha_pub], [vista_en]) SELECT [id], [empresa], [puesto], [requisitos], [contrato], [jornada], [ubicacion], [salario_min], [estado], [fuente], [url_origen], [codigo_externo], [hash], [fecha_pub], [vista_en] FROM " & src & "[VACANTES#csv]"
    X db, "INSERT INTO [USUARIO_HABILIDAD] ([usuario], [habilidad], [nivel]) SELECT [usuario], [habilidad], [nivel] FROM " & src & "[USUARIO_HABILIDAD#csv]"
    X db, "INSERT INTO [PREFERENCIAS] ([id], [usuario], [tipo], [clave], [valor], [peso], [fecha_mod]) SELECT [id], [usuario], [tipo], [clave], [valor], [peso], [fecha_mod] FROM " & src & "[PREFERENCIAS#csv]"
    X db, "INSERT INTO [EVALUACIONES] ([id], [usuario], [vacante], [evaluador], [fecha], [d1_match_cv], [d2_north_star], [d3_compensacion], [d4_cultura], [d5_red_flags], [global], [global_personal], [banda], [explicacion], [hueco], [hash_cv]) SELECT [id], [usuario], [vacante], [evaluador], [fecha], [d1_match_cv], [d2_north_star], [d3_compensacion], [d4_cultura], [d5_red_flags], [global], [global_personal], [banda], [explicacion], [hueco], [hash_cv] FROM " & src & "[EVALUACIONES#csv]"
    X db, "INSERT INTO [FEEDBACK] ([id], [usuario], [vacante], [veredicto], [motivo], [fecha]) SELECT [id], [usuario], [vacante], [veredicto], [motivo], [fecha] FROM " & src & "[FEEDBACK#csv]"
    X db, "INSERT INTO [CERTIFICADOS] ([id], [usuario], [vacante], [evaluacion], [codigo], [firma], [fecha_emision], [fecha_caducidad], [estado], [veces_verificado]) SELECT [id], [usuario], [vacante], [evaluacion], [codigo], [firma], [fecha_emision], [fecha_caducidad], [estado], [veces_verificado] FROM " & src & "[CERTIFICADOS#csv]"
    msg = "Registros importados (esperados):" & vbCrLf
    msg = msg & "CONFIGURACION: " & DCount("*", "CONFIGURACION") & "  (7)" & vbCrLf
    msg = msg & "ENTIDADES: " & DCount("*", "ENTIDADES") & "  (5)" & vbCrLf
    msg = msg & "HABILIDADES: " & DCount("*", "HABILIDADES") & "  (60)" & vbCrLf
    msg = msg & "EVALUADORES: " & DCount("*", "EVALUADORES") & "  (5)" & vbCrLf
    msg = msg & "EMPRESAS: " & DCount("*", "EMPRESAS") & "  (61)" & vbCrLf
    msg = msg & "USUARIOS: " & DCount("*", "USUARIOS") & "  (200)" & vbCrLf
    msg = msg & "VERIFICACIONES: " & DCount("*", "VERIFICACIONES") & "  (123)" & vbCrLf
    msg = msg & "VACANTES: " & DCount("*", "VACANTES") & "  (250)" & vbCrLf
    msg = msg & "USUARIO_HABILIDAD: " & DCount("*", "USUARIO_HABILIDAD") & "  (1502)" & vbCrLf
    msg = msg & "PREFERENCIAS: " & DCount("*", "PREFERENCIAS") & "  (2526)" & vbCrLf
    msg = msg & "EVALUACIONES: " & DCount("*", "EVALUACIONES") & "  (3200)" & vbCrLf
    msg = msg & "FEEDBACK: " & DCount("*", "FEEDBACK") & "  (600)" & vbCrLf
    msg = msg & "CERTIFICADOS: " & DCount("*", "CERTIFICADOS") & "  (40)" & vbCrLf
    MsgBox msg, vbInformation, "LANOPS - Paso 2"
End Sub

Private Function Intento(db As DAO.Database, ByVal sql As String) As String
    On Error Resume Next
    db.Execute sql, dbFailOnError
    If Err.Number = 0 Then Intento = "ADMITIDO (mal)" Else Intento = "rechazado (bien) - error " & Err.Number & ": " & Err.Description
    Err.Clear
End Function

Public Sub Paso3_Probar()
    Dim ws As DAO.Workspace, db As DAO.Database, r As String
    Set ws = DBEngine.Workspaces(0): Set db = CurrentDb
    ws.BeginTrans
    r = "1) Evaluacion de un usuario que no existe (9999): " & Intento(db, "INSERT INTO EVALUACIONES (usuario, vacante, evaluador, fecha, d1_match_cv, d2_north_star, d3_compensacion, d4_cultura, d5_red_flags, [global], banda, hash_cv) VALUES (9999, 1, 1, Date(), 3, 3, 3, 3, 3, 3, ""Media"", ""prueba"")") & vbCrLf & vbCrLf
    r = r & "2) Entidad de tipo no admitido: " & Intento(db, "INSERT INTO ENTIDADES (nombre, tipo) VALUES (""Prueba LANOPS"", ""empresa"")") & vbCrLf & vbCrLf
    r = r & "3) Vacante duplicada (mismo hash): " & Intento(db, "INSERT INTO VACANTES (empresa, puesto, estado, fuente, hash) SELECT TOP 1 empresa, puesto, ""abierta"", ""manual"", hash FROM VACANTES") & vbCrLf & vbCrLf
    r = r & "4) Mismo evaluador puntua dos veces el mismo par con el mismo CV: " & Intento(db, "INSERT INTO EVALUACIONES (usuario, vacante, evaluador, fecha, d1_match_cv, d2_north_star, d3_compensacion, d4_cultura, d5_red_flags, [global], banda, hash_cv) SELECT TOP 1 usuario, vacante, evaluador, fecha, 3, 3, 3, 3, 3, 3, ""Media"", hash_cv FROM EVALUACIONES") & vbCrLf & vbCrLf
    r = r & "Relaciones con integridad: " & Relaciones(db) & " (esperadas: 15)"
    ws.Rollback
    Debug.Print r
    MsgBox r, vbInformation, "LANOPS - Paso 3 (no se ha guardado nada)"
End Sub
