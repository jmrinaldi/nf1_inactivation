#!/bin/bash

##################
# NF1 Inactivation Classifier for Glioblastoma
# (C) Gregory Way 2016
##################

##################
# Step 0 - Download Data
##################
./download_data.sh

##################
# Step 1 - Process Training Data
##################
python scripts/describe_data.py \
--tissue 'GBM' \
--gene 'NF1' \
--type 'Silent'

# Build X matrix
python scripts/build_x.py \
--tissue 'GBM'

# Process RNAseq data
python scripts/process_rnaseq.py \
--tissue 'GBM' \
--scale 'zscore'

# Build Y matrix
python scripts/build_y.py \
--gene 'NF1' \
--tissue 'GBM' \
--y-origin 'data/Y/' \
--filter 'Silent' \
--unclassified

##################
# Step 2 - Cross Validation
##################
# Parameter Sweep Values
alpha_param='0.1,0.15,0.2,0.25,0.3,0.4,0.5,0.7,0.9'
l1_ratio='0.1,0.15,0.18,0.2,0.22,0.24,0.26,0.28,0.3,0.4,0.5,0.6,0.7,0.8,0.9'

# Performs cross validation for the parameter sweep and outputs figures
python scripts/nf1_classifier.py \
--gene 'NF1' \
--tissue 'GBM' \
--output-file 'results/gbm_elasticnet_cv.tsv' \
--classifier 'elasticnet' \
--hyperparameters $alpha_param \
--alt-params $l1_ratio \
--iterations 50 \
--y-origin-fh 'data/Y/'

##################
# Step 3 - Inspect Model
##################
# Optimal Hyperparameters for RNAseq Distribution
optimal_alpha=0.1
optimal_l1=0.28

# Output ROC plots
python scripts/nf1_classifier.py \
--gene 'NF1' \
--tissue 'GBM' \
--classifier 'elasticnet' \
--output-file 'results/roc_output.tsv' \
--iterations 20 \
--hyperparameters $optimal_alpha \
--alt-params $optimal_l1 \
--y-origin-fh 'data/Y/' \
--plot-roc

##################
# Step 4 - Process Validation Data
##################
# Process HTA2.0 CEL files
Rscript scripts/preprocess_validation.r

# Transform X matrix to microarray distribution and zero-one normalize
python scripts/transform_rnaseq.py \
--microarray-fh 'data/validation/normalized/validation_set.tsv' \
--rnaseq-fh 'data/X/raw/GBM_RNAseq_X_matrix.tsv' \
--out-fh 'data/X/tdm/raw_norm_GBM.tsv' \
--normalization 'zscore'

# Output ROC plot for transformed data and get gene coefficients
python scripts/nf1_classifier.py \
--gene 'NF1' \
--tissue 'GBM' \
--classifier 'elasticnet' \
--output-file 'results/roc_tdm_output.tsv' \
--iterations 100 \
--hyperparameters $optimal_alpha_tdm \
--alt-params $optimal_l1_tdm \
--y-origin-fh 'data/Y/' \
--x-origin-fh 'data/X/tdm/raw_norm_' \
--plot-roc \
--coef-weights

##################
# Step 5 - Validation
##################
# To double check performance of processed data, rerun cross validation
python scripts/nf1_classifier.py \
--gene 'NF1' \
--tissue 'GBM' \
--output-file 'results/gbm_elasticnet_unlabeled_tdm_cv.tsv' \
--classifier 'elasticnet' \
--hyperparameters $alpha_param \
--alt-params $l1_ratio \
--iterations 50 \
--y-origin-fh 'data/Y/' \
--x-origin-fh 'data/X/tdm/raw_norm_' \
--validation-sub

# Reset the optimal parameters
optimal_alpha_tdm=0.1
optimal_l1_tdm=0.1

# Apply classifier to validation data
python scripts/validation.py \
validation-fh 'data/validation/normalized/validation_set.tsv' \
x-matrix 'data/X/tdm/raw_norm_GBM.tsv' \
out-fh 'results/validation_results.tsv' \
hyperparameters $optimal_alpha_tdm \
alt-params $optimal_l1_tdm \
ensemble 100

