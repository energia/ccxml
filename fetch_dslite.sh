#!/bin/bash

#./fetch_dslite.sh <path to .ccxml files>
unamestr=`uname`


# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
        echo "** Trapped CTRL-C"
        exit
}

echo "Fetching TICloudAgent Installer"

echo "Installing TICloudagent"

if [[ "$unamestr" == 'Darwin' ]]; then
    wget -O ticloudagent.dmg https://dev.ti.com/ticloudagent/getInstaller?os=osx
    hdiutil attach -mountpoint ./ticloudagent_install ticloudagent.dmg
    ./ticloudagent_install/ticloudagent.app/Contents/MacOS/osx-intel --mode unattended --prefix $(pwd)
    hdiutil detach ./ticloudagent_install
    unset https_proxy http_proxy
elif [[ "$unamestr" == 'Linux' ]]; then
    wget -O ticloudagent.run https://dev.ti.com/ticloudagent/getInstaller?os=linux
    chmod u+x ticloudagent.run
    ./ticloudagent.run --mode unattended --prefix $(pwd)
elif [[ "$unamestr" == 'MINGW32'* ]]; then
    wget --no-check-certificate -O ticloudagent.exe https://dev.ti.com/ticloudagent/getInstaller?os=win
    start //wait ./ticloudagent.exe --mode unattended --prefix $(pwd)
fi

if [[ "$unamestr" == 'MINGW32'* ]]; then
    PWD="$(pwd -W)"
    echo -e "{\n\t\"userDataRoot\" : \"${PWD//\//\\\\\\\\}\\\\\\TICloudAgent\"\n}"  > TICloudAgent/config.json
else
    echo -e "{\n\t\"userDataRoot\" : \"$(pwd)/TICloudAgent\"\n}" > TICloudAgent/config.json
fi

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
elif [[ "$unamestr" == 'MINGW32'* ]]; then
    echo ${string} "Windows"
    eval "zip -r dslite-${DSLITE_VER}-i686-mingw32.zip DSLite"
fi

