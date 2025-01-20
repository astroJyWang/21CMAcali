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

  
singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg wsclean -data-column CORRECTED_DATA -size 4096 4096 -multiscale -scale 0.25amin -niter 1000000 -auto-mask 3 -auto-threshold 0.3 -mgain 0.95 -channels-out 128 -update-model-required $vis
 
echo "# HAKUNA MATATA"
