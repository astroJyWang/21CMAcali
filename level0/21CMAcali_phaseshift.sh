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

PIPE_PATH="." #"/home/jywang/21CMA/21CMAcali"
#vis=${DATA_PATH}/${PREFIX}${CH}".MS"
    
singularity exec -B ${DATA_PATH} ${CONTAINER_PATH}/casa.simg casa --nogui --logfile ${DATA_PATH}/a.log -c ${PIPE_PATH}/21CMAcali_phaseshift.py ${DATA_PATH}/${PREFIX}${CH} 

echo "# HAKUNA MATATA"
