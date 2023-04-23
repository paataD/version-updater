#!/bin/bash

filename="$1"
fileQnt="$2"

if [[ $# -ne 2 ]]; then
      echo "Usage: $0 <filename> <fileQnt>"
      exit 1
fi

find . -maxdepth 1 -name "$filename" -type f -printf "%T@;%Tc;%p\n" | sort -nr | tail -n +"$((fileQnt + 1))" | awk -F ';' '{print $3}' | xargs  --no-run-if-empty  rm -rf