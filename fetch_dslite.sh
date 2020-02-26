#!/bin/bash

#./fetch_dslite.sh <path to .ccxml files>
unamestr=`uname`

#server=btcloudstaging.toro.design.ti.com
server=dev.ti.com

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
        echo "** Trapped CTRL-C"
        exit
}

echo "Fetching TICloudAgent Installer from server ${server}"

echo "Installing TICloudagent"

    unset https_proxy http_proxy
if [[ "$unamestr" == 'Darwin' ]]; then
    wget --no-check-certificate -O ticloudagent.dmg https://${server}/ticloudagent/getInstaller?os=osx
    hdiutil attach -mountpoint ./ticloudagent_install ticloudagent.dmg
    ./ticloudagent_install/ticloudagent.app/Contents/MacOS/osx-intel --mode unattended --prefix $(pwd)
    hdiutil detach ./ticloudagent_install
elif [[ "$unamestr" == 'Linux' ]]; then
    wget --no-check-certificate -O ticloudagent.run https://${server}/ticloudagent/getInstaller?os=linux
    chmod u+x ticloudagent.run
    ./ticloudagent.run --mode unattended --prefix $(pwd)
elif [[ "$unamestr" == 'MINGW32'* ]]; then
    wget --no-check-certificate -O ticloudagent.exe https://${server}/ticloudagent/getInstaller?os=win
    start //wait ./ticloudagent.exe --mode unattended --prefix $(pwd)
fi

if [[ "$unamestr" == 'MINGW32'* ]]; then
    PWD="$(pwd -W)"
    echo -e "{\n\t\"userDataRoot\" : \"${PWD//\//\\\\\\\\}\\\\\\TICloudAgent\"\n}"  > TICloudAgent/config.json
else
    echo -e "{\n\t\"userDataRoot\" : \"$(pwd)/TICloudAgent\"\n}" > TICloudAgent/config.json
fi

read -n 1 -s -r -p "Please edit installer.js and then press any key to continue"

echo "Fetching DSLite"
dslite_dir=$(pwd)/TICloudAgent/loaders/ccs_base

shopt -s nullglob

files=( *.ccxml )
printf '%d ccxml files found\n' "${#files[@]}"

for f in "${files[@]}"; do
  printf 'processing %s\n' "${f}"
  $(pwd)/TICloudAgent/node $(pwd)/TICloudAgent/src/installer/cli.js --host https://${server} --offline 1 --target ${f}
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

