#!/bin/bash

#$ -l mem_free=1G 
#$ -l h_vmem=1G
#$ -cwd
#$ -m e
#$ -M psadil1@jh.edu

# module load conda_R/4.1.x
conda activate biobank

Rscript -e "targets::tar_make_future(script='_targets.R', workers = 1000)"

