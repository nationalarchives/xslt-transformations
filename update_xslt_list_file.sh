#!/bin/bash

echo "Update xslt file with all xslt files within this transformations module."

FILES="src/main/resources/*"

function list_xslt_files {
    for f in `ls $FILES`
    do
        echo ${f##*/}
    done
}

mkdir -p target/resources

list_xslt_files > 'target/resources/transformations_xslt_files.txt'

echo "Completed output of xslt files from resource folder."