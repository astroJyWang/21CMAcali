#vis_prefix="6144:6400"
"""
casa -c selfcal.py <prefix> [solint] [refant]
"""

import sys

vis_prefix=sys.argv[3]
if len(sys.argv)>4:
    solint=sys.argv[4]
else:
    solint="5min"

if len(sys.argv)>5:
    refant=sys.argv[5]
else:
    refant="E01"

vis=vis_prefix+".MS"
flagversion="init.flag"

#flagmanager(vis=vis,mode="restore",versionname=flagversion,oldname="",comment="",merge="replace")

#img_prefix=vis_prefix+"_img"
#model=img_prefix+".model"
#ft(vis=vis,field="",spw="",model=model,nterms=1,reffreq="",complist="",incremental=False,usescratch=True) #using model, no complist applied

caltable=vis_prefix+".cal"

bandpass(vis=vis,caltable=caltable,field="",spw="",intent="",selectdata=False,timerange="",uvrange="",antenna="",scan="",observation="",msselect="",solint=solint,combine="scan",refant=refant,minblperant=4,minsnr=2,solnorm=False,bandtype="B",smodel=[],append=False,fillgaps=0,degamp=3,degphase=3,visnorm=False,maskcenter=0,maskedge=5,docallib=False,callib="",gaintable=[],gainfield=[],interp=[],spwmap=[],parang=False)

applycal(vis=vis,field="",spw="",intent="",selectdata=False,timerange="",uvrange="",antenna="",scan="",observation="",msselect="",docallib=False,callib="",gaintable=[caltable],gainfield=[],interp=[],spwmap=[],calwt=[True],parang=False,applymode="",flagbackup=True)


