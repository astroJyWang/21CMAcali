#! /usr/bin/env bash
#SBATCH --partition=FUSION
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=64
#SBATCH --mem=128000
#SBATCH --time=240:00:00
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out
source ~/.bashrc

DATE=$1
#INPUT_PATH="/home/data/"${DATE}"/raw"
INPUT_PATH="/data/raw/"${DATE}
OUTPUT_PATH="/home/data/"${DATE}"/secondary_backup"

BASIC_PATH="/home/data/basic_data"
CONTAINER_PATH="/home/containers"

PREFIX="ms_"
CH='6144:6656'
INIT_MODEL="components.cl"
SOL_INT="5min"
REF_ANT="E01"

singularity exec -B ${INPUT_PATH} -B ${OUTPUT_PATH} -B ${BASIC_PATH} ${CONTAINER_PATH}/casa.simg /usr/local/bin/raw2ms_splited ${BASIC_PATH}/ANTENNA/ ${OUTPUT_PATH}/${PREFIX} ${DATE} ${INPUT_PATH} ${CH}

echo "# HAKUNA MATATA"
