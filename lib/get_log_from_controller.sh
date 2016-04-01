#!/bin/bash
INPUT_DATA_DIR="raw_outputs"

JOB=$1

if [ $# -eq 0 ]; then
    echo "No arguments: inform job-number "
    exit 1
fi

scp splayd@172.17.0.12:/home/splayd/splay/src/controller/logs/$JOB raw_outputs
