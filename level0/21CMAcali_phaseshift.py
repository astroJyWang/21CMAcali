import sys
vis_prefix=sys.argv[3]

vis=vis_prefix+".MS"
out_vis=vis_prefix+"_phaseshift.MS"


#phaseshift(vis=vis, outputvis=out_vis, phasecenter='J2000 00:00:00 +89:59:59.999')
mstransform(vis=vis, outputvis=out_vis, datacolumn='DATA', phasecenter="J2000 00h00m00 +89d59m59.99")
