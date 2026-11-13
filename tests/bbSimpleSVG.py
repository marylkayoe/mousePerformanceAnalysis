"""Small editable SVG plot primitives for diagnostic comparison sheets."""
import html,math
import numpy as np
class Figure:
 def __init__(self,nr,nc,width=1200,rowheight=320):
  self.nr=nr;self.nc=nc;self.width=width;self.height=nr*rowheight+65;self.parts=[];self.axes=[[Axis(self,j*width/nc,i*rowheight+55,width/nc,rowheight) for j in range(nc)] for i in range(nr)]
 def text(self,x,y,s,size=16,anchor='start',color='#222'):self.parts.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{color}">{html.escape(str(s))}</text>')
 def save(self,path):path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.width}" height="{self.height}" viewBox="0 0 {self.width} {self.height}"><rect width="100%" height="100%" fill="white"/>'+''.join(self.parts)+'</svg>')
class Axis:
 def __init__(self,f,x,y,w,h):self.f=f;self.left=x+65;self.top=y+40;self.w=w-95;self.h=h-100
 def setup(self,xlim,ylim,title,ylabel,xticks=None,xticklabels=None,xlabel=None):
  self.xlim=xlim;self.ylim=ylim;f=self.f;f.text(self.left,self.top-23,title,17);f.text(self.left,self.top-4,ylabel,13)
  self.line([xlim[0],xlim[0],xlim[1]],[ylim[1],ylim[0],ylim[0]],'#333',1)
  for v in np.linspace(*ylim,4):
   xx,yy=self.xy(xlim[0],v);f.text(xx-7,yy+5,(f'{v:,.0f}' if abs(v)>=1000 else f'{v:.3g}'),14,'end')
  if xticks is None:xticks=np.linspace(*xlim,5)
  for i,v in enumerate(xticks):
   xx,yy=self.xy(v,ylim[0]);f.text(xx,yy+21,xticklabels[i] if xticklabels else f'{v:.3g}',15,'middle')
  if xlabel:f.text(self.left+self.w/2,self.top+self.h+44,xlabel,14,'middle')
 def xy(self,x,y):return self.left+(x-self.xlim[0])/(self.xlim[1]-self.xlim[0])*self.w,self.top+(self.ylim[1]-y)/(self.ylim[1]-self.ylim[0])*self.h
 def line(self,x,y,color,width=1.5,dash=False):
  path='';pen=False
  for a,b in zip(x,y):
   if not math.isfinite(a) or not math.isfinite(b):pen=False;continue
   xx,yy=self.xy(a,b);path+=('L' if pen else 'M')+f'{xx:.2f},{yy:.2f} ';pen=True
  self.f.parts.append(f'<path d="{path}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linejoin="round"'+(' stroke-dasharray="5 5"' if dash else '')+'/>')
 def dot(self,x,y,color,diamond=False,opacity=1):
  xx,yy=self.xy(x,y)
  if diamond:self.f.parts.append(f'<path d="M{xx-4},{yy} l4,-6 l4,6 l-4,6 Z" fill="{color}" stroke="#333" stroke-width=".6"/>')
  else:self.f.parts.append(f'<circle cx="{xx}" cy="{yy}" r="4" fill="{color}" opacity="{opacity}"/>')
 def p(self,v):self.f.text(self.left+self.w-4,self.top+19,f'p = {v:.3f}' if v>=.001 else 'p < 0.001',14,'end')
