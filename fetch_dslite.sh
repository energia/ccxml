#!/bin/bash

#./fetch_dslite.sh <path to .ccxml files>

echo "Fetching DSLite"

dslite_dir=~/.ti/TICloudAgent/loaders/ccs_base

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 0;
fi

shopt -s nullglob

files=( *.ccxml )
printf '%d ccxml files found\n' "${#files[@]}"

for f in "${files[@]}"; do
  printf 'processing %s\n' "${f}"
  $1/node $1/src/installer/cli.js --host http://vmtgccscloud00.toro.design.ti.com --offline 1 --target ${f}
done

echo "Packing DSLite"
rm -r DSLite
mkdir -p DSLite
cp -r ${dslite_dir}/* DSLite/

DSLITE_VER="$(DSLite/DebugServer/bin/DSLite help | sed -n "s/^.*version \([0-9.]*\).*/\1/p")"
echo "DSLite version is:" ${DSLITE_VER}

string="Creating archive for "

unamestr=`uname`
if [[ "$unamestr" == 'Darwin' ]]; then
    echo ${string} "MacOS"
    eval "tar -cjf dslite-${DSLITE_VER}-x86_64-apple-darwin.tar.bz2 DSLite"
elif [[ "$unamestr" == 'Linux' ]]; then
    echo ${string} "Linux"
    eval "tar -cjf dslite-${DSLITE_VER}-i386-x86_64-pc-linux-gnu.tar.bz2 DSLite"
elif [[ "$unamestr" == 'MINGW32_NT-6.2' ]]; then
    echo ${string} "Windows"
    eval "zip -r dslite-${DSLITE_VER}-i686-mingw32.zip DSLite"
fi

