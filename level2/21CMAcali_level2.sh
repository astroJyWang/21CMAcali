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
PIPE_PATH="."
vis=${DATA_PATH}/${PREFIX}${CH}".MS"

for i  in `seq 1 3`

do

    echo "#round $i"

    #singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg casa --nogui --logfile ${DATA_PATH}/a.log -c ${PIPE_PATH}/flagmanager.py ${DATA_PATH}/${PREFIX}${CH} 
    
    singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg aoflagger -column CORRECTED_DATA -strategy ${PIPE_PATH_0}/mwa-default.lua $vis  
    ### singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg aoflagger -column CORRECTED_DATA -strategy ${PIPE_PATH_0}/21CMA_strategy $vis  
    
    singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg casa --nogui --logfile ${DATA_PATH}/a.log -c ${PIPE_PATH}/21CMAcali_level2.py ${DATA_PATH}/${PREFIX}${CH} ${SOL_INT} ${REF_ANT}

    singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg wsclean -data-column CORRECTED_DATA -size 4096 4096 -multiscale -scale 0.25amin -niter 1000000 -auto-mask 3 -auto-threshold 0.3 -mgain 0.95 -update-model-required $vis
    ### singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg wsclean -data-column CORRECTED_DATA -size 4096 4096 -multiscale -scale 0.25amin -niter 1000000 -auto-mask 5 -mgain 0.95 -update-model-required $vis
    ### singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg wsclean -data-column CORRECTED_DATA -size 4096 4096 -scale 0.25amin -niter 1000000 -auto-mask 5 -mgain 0.95 -update-model-required $vis
    ### singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg wsclean -data-column CORRECTED_DATA -size 4096 4096 -scale 0.25amin -niter 1000000 -auto-mask 5 -mgain 0.95 -channels-out 128 -update-model-required $vis

    #cp img.fits img_v${i}.fits
    cp wsclean-dirty.fits wsclean-dirty_v${i}.fits
    cp wsclean-image.fits wsclean-image_v${i}.fits
    cp wsclean-model.fits wsclean-model_v${i}.fits
    cp wsclean-psf.fits wsclean-psf_v${i}.fits
    cp wsclean-residual.fits wsclean-residual_v${i}.fits


done

echo "# HAKUNA MATATA"
