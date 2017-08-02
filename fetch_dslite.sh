#!/bin/bash

#./fetch_dslite.sh <path to .ccxml files>
unamestr=`uname`

echo "Fetching TICloudAgent Installer"
wget -O ticloudagent.run https://dev.ti.com/ticloudagent/getInstaller?os=linux

echo "Installing TICloudagent"
chmod u+x ticloudagent.run
./ticloudagent.run --mode unattended --prefix $(pwd)

echo -e "{\n\t\"userDataRoot\" : \"$(pwd)/TICloudAgent\"\n}" > TICloudAgent/config.json

echo "Fetching DSLite"
dslite_dir=$(pwd)/TICloudAgent/loaders/ccs_base

shopt -s nullglob

files=( *.ccxml )
printf '%d ccxml files found\n' "${#files[@]}"

for f in "${files[@]}"; do
  printf 'processing %s\n' "${f}"
  $(pwd)/TICloudAgent/node $(pwd)/TICloudAgent/src/installer/cli.js --host https://dev.ti.com --offline 1 --target ${f}
done

echo "Packing DSLite"
rm -r DSLite
cp -r "${dslite_dir}" DSLite
cp *.ccxml DSLite/

DSLITE_VER="$(DSLite/DebugServer/bin/DSLite help | sed -n "s/^.*version \([0-9.]*\).*/\1/p")"
echo "DSLite version is:" ${DSLITE_VER}

string="Creating archive for "

if [[ "$unamestr" == 'Darwin' ]]; then
    echo ${string} "MacOS"
    eval "tar -cjf dslite-${DSLITE_VER}-x86_64-apple-darwin.tar.bz2 DSLite"
elif [[ "$unamestr" == 'Linux' ]]; then
    echo ${string} "Linux"
    eval "tar -cjf dslite-${DSLITE_VER}-i386-x86_64-pc-linux-gnu.tar.bz2 DSLite"
elif [[ "$unamestr" == '*MINGW32*' ]]; then
    echo ${string} "Windows"
    eval "zip -r dslite-${DSLITE_VER}-i686-mingw32.zip DSLite"
fi

