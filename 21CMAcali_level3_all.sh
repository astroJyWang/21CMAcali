#!/usr/bin/env bash
#SBATCH --partition=FUSION
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=64
#SBATCH --mem=128000
#SBATCH --time=480:00:00
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out

source ~/.bashrc

function singularity_run_old_script(){
    singularity exec -B /home -B /data /data/containers/ddf_7.0 $@
}

function singularity_run(){
    singularity exec -B /home/ -B /data /data/containers/kms $@
    #singularity exec -B /home -B /data /home/containers/ddf $@
}

DATE=$1
CH='6144:6400'

DATA_PATH="/home/data/${DATE}/secondary"
PREFIX="ms_"

OUT_PREFIX=kMS_21CMA
INPUT_MS=${DATA_PATH}/${PREFIX}${CH}.MS
NCPUS=64

echo "# 21CMAcali Level-3 start ..."

singularity_run DDF.py --Data-MS ${INPUT_MS} --Data-ColName CORRECTED_DATA --Output-Name ${OUT_PREFIX}_DI --Image-Cell 10 --Image-NPix 9000 --Output-Mode Dirty --Facets-DiamMin 0.2 --Facets-DiamMax 2 --Parallel-NCPU ${NCPUS} --Data-ChunkHours 0.25 --Freq-NBand 4 --Freq-NDegridBand 8 --RIME-DecorrMode FT --Weight-ColName None --Cache-Reset 1 --Selection-UVRangeKm 0.1,3000 --Deconv-MaxMajorIter 5 --Weight-Mode=Briggs --Weight-Robust -1.5 --Log-Memory=1 --Data-Sort 1 --Cache-Dir=. 
echo "# Step-1 done"

# ds9 ${OUT_PREFIX}_DI.dirty.fits

singularity_run_old_script MakeModel.py --ds9PreClusterFile ./ds9_kMS.reg --NCluster=0 --BaseImageName=${OUT_PREFIX}_DI
echo "# Step-3 done"

singularity_run DDF.py ${OUT_PREFIX}_DI.parset --Output-Name ${OUT_PREFIX}_DI_Clustered --Output-Mode Clean --Facets-CatNodes ./ds9_kMS.reg.ClusterCat.npy --Deconv-Mode SSD2 --SSD2-PolyFreqOrder 3 --Deconv-MaxMajorIter 5 --Deconv-Gain 0.02 --Deconv-RMSFactor=3.0 --Mask-Auto 1 --Data-ChunkHours 0.25 --Weight-Mode=Briggs --Weight-Robust -1.5 --Log-Memory=1 
echo "# Step-4 done"

singularity_run_old_script MakeMask.py --RestoredIm  ${OUT_PREFIX}_DI_Clustered.app.restored.fits --Th 18 
echo "# Step-5 done"

singularity_run DDF.py ${OUT_PREFIX}_DI_Clustered.parset --Output-Name ${OUT_PREFIX}_DI_Clustered.DeeperDeconv --Predict-InitDicoModel ${OUT_PREFIX}_DI_Clustered.DicoModel --Cache-Reset 0 --Cache-Dirty forceresidual --Cache-PSF force --Deconv-Mode SSD2 --SSD2-PolyFreqOrder 3 --Deconv-MaxMajorIter 5 --Deconv-Gain 0.02 --Deconv-RMSFactor=3.0 --Mask-Auto 0 --Mask-External ${OUT_PREFIX}_DI_Clustered.app.restored.fits.mask.fits --Data-ChunkHours 0.25 --Weight-Mode=Briggs --Weight-Robust -1.5 --Log-Memory=1
echo "# Step-6 done"

singularity_run kMS.py --MSName ${INPUT_MS} --FieldID 0 --SolverType KAFCA --PolMode Scalar --BaseImageName ${OUT_PREFIX}_DI_Clustered.DeeperDeconv --dt 5 --NCPU ${NCPUS} --OutSolsName DD0 --NChanSols 4 --InCol CORRECTED_DATA --TChunk 0.25 --BeamModel None #--Weighting=Briggs --Robust=-1.5 # --Weighting Uniform 
echo "# Step-7 done"

singularity_run DDF.py ${OUT_PREFIX}_DI_Clustered.DeeperDeconv.parset --Output-Name ${OUT_PREFIX}_DI_Clustered.DeeperDeconv.AP --Cache-Reset 1 --Cache-PSF auto --Cache-Dirty auto --Predict-InitDicoModel ${OUT_PREFIX}_DI_Clustered.DeeperDeconv.DicoModel --DDESolutions-DDSols DD0 --Data-ChunkHours 0.25  --Weight-Mode=Briggs --Weight-Robust -1.5 --Log-Memory=1
echo "# Step-8 done"

echo "### HAKUNA MATATA ###"
