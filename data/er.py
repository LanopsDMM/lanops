import sys; import os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from esquema import T
FK={'VERIFICACIONES','USUARIO_HABILIDAD','FEEDBACK'}
fks={('USUARIOS','recomendado_por'),('VACANTES','empresa'),('PREFERENCIAS','usuario'),('EVALUACIONES','usuario'),('EVALUACIONES','vacante'),
     ('EVALUACIONES','evaluador'),('CERTIFICADOS','usuario'),('CERTIFICADOS','vacante'),('CERTIFICADOS','evaluacion')}
cols={t[0]:[c['col'] for c in t[2]] for t in T}
def ent(name, pos, color, sub=None):
    at=[c for c in cols[name] if (name,c) not in fks]
    pk=at[0]; rest=at[1:]
    cells=['<U>%s</U>'%pk]+rest
    ncol=2 if len(cells)>7 else 1
    rows=[cells[i:i+ncol] for i in range(0,len(cells),ncol)]
    h='<TR><TD COLSPAN="%d" BGCOLOR="%s"><FONT COLOR="white"><B>%s</B></FONT>%s</TD></TR>'%(ncol,color,name,('<BR/><FONT POINT-SIZE="9" COLOR="white">%s</FONT>'%sub) if sub else '')
    body=''.join('<TR>'+''.join('<TD ALIGN="LEFT">%s</TD>'%c for c in r)+('<TD></TD>'*(ncol-len(r)))+'</TR>' for r in rows)
    return '%s [shape=plain pos="%s!" label=<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="3" BGCOLOR="#FAFAF8">%s%s</TABLE>>];\n'%(name,pos,h,body)
def rel(n,label,pos,attrs=None):
    x='%s [shape=diamond style=filled fillcolor="#EEF2F7" label="%s" pos="%s!" fontsize=11 width=1.5 height=0.8 fixedsize=true];\n'%(n,label,pos)
    if attrs:
        x+='%s_a [shape=plaintext fontsize=9 fontcolor="#444444" label="%s" pos="%s!"];\n'%(n,attrs,attrs_pos[n])
        x+='%s -- %s_a [style=dotted color="#888888"];\n'%(n,n)
    return x
def e(a,b,ta,tb):
    return '%s -- %s [taillabel="%s" headlabel="%s" labeldistance=1.6 labelfontsize=11 labelfontcolor="#B00020"];\n'%(a,b,ta,tb)
BL,GR,RD,VI,BR='#1F5FA8','#0F6E56','#9A3412','#5B4BB7','#8A5A00'
attrs_pos={'verifica':'0.0,5.3','tiene':'2.4,2.9','marca':'9.0,9.6'}
g='graph ER {\nlayout=neato; splines=true; overlap=false; outputorder=edgesfirst;\nnode [fontname="DejaVu Sans" fontsize=10]; edge [color="#555555"];\n'
g+='titulo [shape=plaintext fontsize=16 fontname="DejaVu Sans Bold" label="LANOPS · Modelo Entidad-Relación" pos="7.5,11.2!"];\n'
g+='leyenda [shape=plaintext fontsize=9 fontcolor="#444444" label="Rectángulo = entidad · rombo = relación · 1 / N = cardinalidad · subrayado = clave · las claves foráneas no se dibujan: las representan los rombos" pos="7.5,10.8!"];\n'
g+=ent('ENTIDADES','0,8.8',BL)
g+=ent('USUARIOS','4.3,7.2',BL)
g+=ent('PREFERENCIAS','0,1.9',BL)
g+=ent('HABILIDADES','4.3,1.3',GR)
g+=ent('EMPRESAS','14,8.8',RD)
g+=ent('VACANTES','14,4.6',RD)
g+=ent('EVALUADORES','14,0.9',VI)
g+=ent('EVALUACIONES','8.9,4.5',VI,'entidad asociativa: N:M usuario–vacante')
g+=ent('CERTIFICADOS','8.9,0.7',BR)
g+=rel('recomienda','recomienda','4.3,10.0')
g+=rel('verifica','verifica','0,6.3','tipo · fecha · estado · verificado_por')
g+=rel('define','define','1.9,4.3')
g+=rel('tiene','tiene','4.3,3.9','nivel (1–5)')
g+=rel('publica','publica','14,6.9')
g+=rel('marca','marca','9.0,8.9','veredicto · motivo · fecha')
g+=rel('evaluado','es evaluado','6.6,5.8')
g+=rel('evaluada','se evalúa','11.6,4.6')
g+=rel('rellena','rellena','11.6,1.9')
g+=rel('nace','nace de','8.9,2.35')
g+=e('USUARIOS','recomienda','1','').replace('headlabel=""','headlabel=""')
g+='USUARIOS -- recomienda [tailport=ne headport=e taillabel="N" labelfontsize=11 labelfontcolor="#B00020" labeldistance=1.6];\n'
g+='USUARIOS -- recomienda [tailport=nw headport=w taillabel="1" labelfontsize=11 labelfontcolor="#B00020" labeldistance=1.6];\n'
g=g.replace(e('USUARIOS','recomienda','1',''),'')
g+=e('ENTIDADES','verifica','N','')+e('verifica','USUARIOS','','M')
g+=e('USUARIOS','define','1','')+e('define','PREFERENCIAS','','N')
g+=e('USUARIOS','tiene','N','')+e('tiene','HABILIDADES','','M')
g+=e('EMPRESAS','publica','1','')+e('publica','VACANTES','','N')
g+=e('USUARIOS','marca','N','')+e('marca','VACANTES','','M')
g+=e('USUARIOS','evaluado','1','')+e('evaluado','EVALUACIONES','','N')
g+=e('VACANTES','evaluada','1','')+e('evaluada','EVALUACIONES','','N')
g+=e('EVALUADORES','rellena','1','')+e('rellena','EVALUACIONES','','N')
g+=e('EVALUACIONES','nace','1','')+e('nace','CERTIFICADOS','','N')
g+='}\n'
open('er.dot','w').write(g)
