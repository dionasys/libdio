#!/bin/bash
INPUT_DATA_DIR="raw_outputs"

JOB=$1

if [ $# -eq 0 ]; then
    echo "No arguments: inform job-number "
    exit 1
fi

scp heversonr@130.125.11.233:/home/heversonr/dionasys_unine/implementations/lib/raw_outputs/$JOB raw_outputs/
