#!/bin/bash

# Specify the directory you want to explore
directory="./"

# Find all files and directories within the specified directory
find "$directory" -print0 | while IFS= read -r -d '' entry; do
    echo "Entry: $entry"
done