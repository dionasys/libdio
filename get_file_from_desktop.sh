#!/bin/bash
BASE_DIR="/home/heversonr/dionasys_unine/implementations/lib/"

FILE_PATH=$1

if [ $# -eq 0 ]; then
    echo "No arguments: inform file path from /home/heversonr/dionasys_unine/implementations/lib/  "
    exit 1
fi

scp heversonr@130.125.11.233:$BASE_DIR/$FILE_PATH . 
