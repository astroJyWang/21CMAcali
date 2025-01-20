#vis_prefix="6144:6400"
"""
casa -c init_process_cmd.py <prefix> <complist> [solint] [refant]
"""

import sys
vis_prefix=sys.argv[3]
complist=sys.argv[4]

if len(sys.argv)>5:
    solint=sys.argv[5]
else:
    solint="5min"

if len(sys.argv)>6:
    refant=sys.argv[6]
else:
    refant="E01"


model=""

vis=vis_prefix+".MS"
flagversion="init.flag"
caltable=vis_prefix+".cal"

ft(vis=vis,field="",spw="",model=model,nterms=1,reffreq="",complist=complist,incremental=False,usescratch=True) #model is empty, complist is from components.cl

bandpass(vis=vis,caltable=caltable,field="",spw="",intent="",selectdata=False,timerange="",uvrange="",antenna="",scan="",observation="",msselect="",solint=solint,combine="scan",refant=refant,minblperant=4,minsnr=2,solnorm=False,bandtype="B",smodel=[],append=False,fillgaps=0,degamp=3,degphase=3,visnorm=False,maskcenter=0,maskedge=5,docallib=False,callib="",gaintable=[],gainfield=[],interp=[],spwmap=[],parang=False)

applycal(vis=vis,field="",spw="",intent="",selectdata=False,timerange="",uvrange="",antenna="",scan="",observation="",msselect="",docallib=False,callib="",gaintable=[caltable],gainfield=[],interp=[],spwmap=[],calwt=[True],parang=False,applymode="",flagbackup=True)

