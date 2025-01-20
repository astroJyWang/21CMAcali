#!/usr/bin/env bash
#SBATCH --partition=FUSION
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=64
#SBATCH --mem=128000
#SBATCH --time=480:00:00
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out

source ~/.bashrc

function singularity_run(){
    #singularity exec -B /home/ -B /data /data/containers/kms $@ || exit
    #singularity exec -B /home/ /home/jywang/work/21CMA/containers/killms_20240409.simg $@ || exit
    
    (singularity exec -B /home/ -B /data /home/jywang/work/21CMA/containers/killms_20240409_debug.simg $@ | tee -a stdout.log) 3>&1 1>&2 2>&3 | tee -a stderr.log || exit
}


DATE=$1
CH='6144:6656'

#DATA_PATH="/home/jywang/work/21CMA/data/${DATE}/secondary"
DATA_PATH="/data/jywang/21CMA_data/${DATE}/secondary"
Cache_PATH=${DATA_PATH}
PREFIX="ms_"

OUT_PREFIX=kMS_21CMA
INPUT_MS=${DATA_PATH}/${PREFIX}${CH}.MS
NCPUS=256

# parameters need to be checked #
total_ch=512
DDF_Freq_NBand=8
DDF_Freq_NDegridBand=8
kMS_NChanSols=8 #num of solutions along freq

#total_ch = DDF_Beam_NBand * kMS_NChanBeamPerMS
DDF_Beam_NBand=4 #number of neighbour channels use the same beam
kMS_NChanBeamPerMS=128

robust=-1.5

echo -n "# 21CMAcali Level-3 start @"
time=$(date "+%Y-%m-%d %H:%M:%S");echo $time

singularity_run DDF.py --Data-MS ${INPUT_MS} --Data-ColName CORRECTED_DATA --Output-Name ${OUT_PREFIX}_DI --Image-Cell 15 --Image-NPix 4096 --Output-Mode Dirty --Facets-DiamMin 0.1 --Facets-DiamMax 1 --Parallel-NCPU ${NCPUS} --Data-ChunkHours 0.25 --Freq-NBand ${DDF_Freq_NBand} --Freq-NDegridBand  ${DDF_Freq_NDegridBand} --RIME-DecorrMode FT --Weight-ColName None --Cache-Reset 1 --Selection-UVRangeKm 0.1,3 --Deconv-MaxMajorIter 5 --Weight-Mode=Briggs --Weight-Robust ${robust} --Log-Memory=1 --Data-Sort 1 --Cache-Dir=${Cache_PATH}  --Beam-Model FITS  --Beam-NBand ${DDF_Beam_NBand} --Beam-FITSParAngleIncDeg 2. --Beam-FITSFile='/home/jywang/work/21CMA/21CMAcali/21CMAcali_beam_model/6144_6656_bin4/21CMAbeam_6144_6656_bin4_$(xy)_$(reim).fits' --Beam-FITSFeed xy --Beam-CenterNorm 1 --Beam-ApplyPJones 0 
echo -n "# Step-1 done @"
time=$(date "+%Y-%m-%d %H:%M:%S");echo $time

## ds9 ${OUT_PREFIX}_DI.dirty.fits

singularity_run MakeModel.py --ds9PreClusterFile ./ds9_kMS.reg --NCluster=0 --BaseImageName=${OUT_PREFIX}_DI
echo -n "# Step-3 done @"
time=$(date "+%Y-%m-%d %H:%M:%S");echo $time

singularity_run DDF.py ${OUT_PREFIX}_DI.parset --Output-Name ${OUT_PREFIX}_DI_Clustered --Output-Mode Clean --Facets-CatNodes ./ds9_kMS.reg.ClusterCat.npy --Deconv-Mode SSD2 --SSD2-PolyFreqOrder 3 --Deconv-MaxMajorIter 5 --Deconv-Gain 0.02 --Deconv-RMSFactor=3.0 --Mask-Auto 1 --Data-ChunkHours 0.25 --Weight-Mode=Briggs --Weight-Robust ${robust} --Log-Memory=1 
echo -n "# Step-4 done @"
time=$(date "+%Y-%m-%d %H:%M:%S");echo $time

singularity_run MakeMask.py --RestoredIm  ${OUT_PREFIX}_DI_Clustered.app.restored.fits --Th 18 
echo -n "# Step-5 done @"
time=$(date "+%Y-%m-%d %H:%M:%S");echo $time

singularity_run DDF.py ${OUT_PREFIX}_DI_Clustered.parset --Output-Name ${OUT_PREFIX}_DI_Clustered.DeeperDeconv --Predict-InitDicoModel ${OUT_PREFIX}_DI_Clustered.DicoModel --Cache-Reset 0 --Cache-Dirty forceresidual --Cache-PSF force --Deconv-Mode SSD2 --SSD2-PolyFreqOrder 3 --Deconv-MaxMajorIter 5 --Deconv-Gain 0.02 --Deconv-RMSFactor=3.0 --Mask-Auto 0 --Mask-External ${OUT_PREFIX}_DI_Clustered.app.restored.fits.mask.fits --Data-ChunkHours 0.25 --Weight-Mode=Briggs --Weight-Robust ${robust} --Log-Memory=1 --Beam-Smooth 1 --Beam-SmoothNPix 11 --Beam-SmoothInterpMode Log
echo -n "# Step-6 done @"
time=$(date "+%Y-%m-%d %H:%M:%S");echo $time

singularity_run kMS.py --MSName ${INPUT_MS} --FieldID 0 --SolverType KAFCA --PolMode Scalar --BaseImageName ${OUT_PREFIX}_DI_Clustered.DeeperDeconv --dt 5 --NCPU ${NCPUS} --OutSolsName DD0 --NChanSols ${kMS_NChanSols} --InCol CORRECTED_DATA --TChunk 0.25 --BeamModel FITS --FITSParAngleIncDeg 2 --FITSFile='/home/jywang/work/21CMA/21CMAcali/21CMAcali_beam_model/6144_6656_bin4/21CMAbeam_6144_6656_bin4_$(xy)_$(reim).fits' --CenterNorm 1 --FITSFeed xy --NChanBeamPerMS ${kMS_NChanBeamPerMS} #--Weighting=Briggs --Robust=-1.5 # --Weighting Uniform 
echo -n "# Step-7 done @"
time=$(date "+%Y-%m-%d %H:%M:%S");echo $time

###singularity_run DDF.py ${OUT_PREFIX}_DI_Clustered.DeeperDeconv.parset --Output-Name ${OUT_PREFIX}_DI_Clustered.DeeperDeconv.AP --Cache-Reset 1 --Cache-PSF auto --Cache-Dirty auto --Predict-InitDicoModel ${OUT_PREFIX}_DI_Clustered.DeeperDeconv.DicoModel --DDESolutions-DDSols DD0 --Data-ChunkHours 0.25  --Weight-Mode=Briggs --Weight-Robust ${robust} --Log-Memory=1 --Beam-Smooth 1 --Beam-SmoothNPix 21 --Beam-SmoothInterpMode Log
singularity_run DDF.py ${OUT_PREFIX}_DI_Clustered.DeeperDeconv.parset --Output-Name ${OUT_PREFIX}_DI_Clustered.DeeperDeconv.AP --Cache-Reset 1 --Cache-PSF auto --Cache-Dirty auto --Predict-InitDicoModel ${OUT_PREFIX}_DI_Clustered.DeeperDeconv.DicoModel --DDESolutions-DDSols DD0 --Data-ChunkHours 0.25  --Weight-Mode=Briggs --Weight-Robust ${robust} --Log-Memory=1 --Beam-Smooth 1 --Beam-SmoothNPix 11 --Beam-SmoothInterpMode Log --Output-Cubes=DdMmRrIiPpFf
echo -n "# Step-8 done @"
time=$(date "+%Y-%m-%d %H:%M:%S");echo $time

echo "### HAKUNA MATATA ###"
