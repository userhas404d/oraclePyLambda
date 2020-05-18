#!/usr/bin/env bash

set -e

function error_exit() {
    echo "$(tput setaf 4)$1$(tput sgr0)" 1>&2
    exit 1
}

PYTHON_VERSION="python3.7"

# Ensure required bins were installed
echo "create-layer: running requirements check"
command -v zip > /dev/null 2>&1 || (echo "zip not available"; exit 1)
command -v pip3 > /dev/null 2>&1 || (echo "pip3 not available"; exit 1)

PROJECT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )"/.. >/dev/null 2>&1 && pwd )
echo "create-layer: running against $PROJECT_DIR"

mapfile -t directories < <(find "$PROJECT_DIR" -name 'requirements.layer.txt' -exec dirname {} \; | sort -u | grep -v "\.terraform\b\|\.terragrunt-cache\b")

for dir in "${directories[@]}"
do
  cd "${dir}" || error_exit "Unable to navigate to ${dir}"
  working_dir="$(pwd)"
  lambda_package="$working_dir/lambda-package"
  layer_path="$lambda_package/python/lib/$PYTHON_VERSION/site-packages/"
  mkdir -p "$layer_path" || error_exit "Unable to create $layer_path"
  pip3 install -r requirements.layer.txt -t "$layer_path" || error_exit "Encountered error installing python dependency"
  pushd lambda-package/ || error_exit "Unable to navigate to lambda-package/"
  zip -r "$working_dir/python.zip" python/* -x "setuptools*/*" "pkg_resources/*" "easy_install*" >/dev/null 2>&1 || error_exit "encountered error when compressing archive"
  popd || error_exit "Unable to return to source directory"
  rm -rf "$lambda_package"
done

curl -L https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basiclite-linux.x64-19.6.0.0.0dbru.zip -o oracle-instant-client.zip
# create a new oracle-instant-client zip with libaio
unzip oracle-instant-client.zip && rm oracle-instant-client.zip
mv ./instantclient_*/ lib
# copy the aio libraries into the lib directory
find /usr/lib64 -type f -name "*aio*" -exec cp {} lib \;
# symlink version 1.0.1 to version 1
ln lib/libaio.so.1.0.1 lib/libaio.so.1
# only support 19.1 - the other version are just symlinks to .19.1
# which on anything other than lambda layers is fine.. 
zip -r oracle_client_lib.zip ./lib/* -x "*.10.1" "*.11.1" "*.18.1" "*.12.1"
rm -rf ./lib

# # add libaio to the lambda/lib directory
# find /usr/lib64 -type f -name "*aio*" -exec cp {} ../lambda_lib \;
# ln ../lambda_lib/libaio.so.1.0.1 ../lambda_lib/libaio.so.1
