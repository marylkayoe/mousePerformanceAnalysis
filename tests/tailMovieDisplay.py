"""Display-only smoothing and bounded gap interpolation; never changes detection."""
import numpy as np

def prepare(values, valid, window=5, gap=4):
    x=np.array(values,float,copy=True); good=np.asarray(valid,bool).copy()
    x[~good]=np.nan
    filled=np.zeros(len(x),bool)
    for lo in np.flatnonzero(~good & np.r_[True,good[:-1]]):
        hi=lo
        while hi<len(x) and not good[hi]: hi+=1
        if lo>0 and hi<len(x) and hi-lo<=gap:
            for k in range(lo,hi): x[k]=x[lo-1]+(x[hi]-x[lo-1])*(k-lo+1)/(hi-lo+1)
            filled[lo:hi]=True
    good|=filled; out=np.full_like(x,np.nan)
    for k in np.flatnonzero(good):
        lo=k;hi=k+1
        while lo>max(0,k-window//2) and good[lo-1]:lo-=1
        while hi<min(len(x),k+window//2+1) and good[hi]:hi+=1
        out[k]=x[lo:hi].mean(axis=0)
    return out,filled

def color(value,limits):
    if not np.isfinite(value):return (130,130,130)
    f=float(np.clip((value-limits[0])/(limits[1]-limits[0]),0,1))
    return (round(25+215*f),round(25*(1-f)),round(25*(1-f)))
