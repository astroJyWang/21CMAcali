#! /usr/bin/env bash
#SBATCH --partition=FUSION
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=64
#SBATCH --mem=128000
#SBATCH --time=480:00:00
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out

source ~/.bashrc

DATE=$1
DATA_PATH="/home/data/"${DATE}"/secondary/"
CONTAINER_PATH="/home/containers/"
PREFIX="ms_"

CH='6144:6656'
SOL_INT="5min"
REF_ANT="E01"

PIPE_PATH_0="/home/jywang/21CMA/21CMAcali"
PIPE_PATH='.' #"/home/jywang/21CMA/21CMAcali"
vis=${DATA_PATH}/${PREFIX}${CH}".MS"
BASIC_PATH="/home/data/basic_data"
INIT_complist="components.cl"

echo "#round 0"

singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg aoflagger -strategy ${PIPE_PATH_0}/generic-default.lua $vis
# singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg aoflagger -v $vis #first round so no para set 
    
singularity exec -B ${DATA_PATH} -B ${BASIC_PATH} ${CONTAINER_PATH}/casa.simg casa --nogui --logfile ${DATA_PATH}/a.log -c ${PIPE_PATH}/21CMAcali_level1.py ${DATA_PATH}/${PREFIX}${CH} ${BASIC_PATH}/${INIT_complist} ${SOL_INT} ${REF_ANT}

singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg wsclean -data-column CORRECTED_DATA -size 4096 4096 -scale 0.25amin -niter 1000000 -auto-mask 5 -mgain 0.95 -update-model-required $vis

cp wsclean-dirty.fits wsclean-dirty_v0.fits
cp wsclean-image.fits wsclean-image_v0.fits
cp wsclean-model.fits wsclean-model_v0.fits
cp wsclean-psf.fits wsclean-psf_v0.fits
cp wsclean-residual.fits wsclean-residual_v0.fits

echo "# HAKUNA MATATA"
