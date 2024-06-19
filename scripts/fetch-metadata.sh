#!/usr/bin/env bash

XIAOYA_ALIST_HOST=http://xiaoya-real.host
METADATA_DIR=/media
EMBY_CONFIG_DIR=/config
TEMP_DIR=/metadata-cache

XIAOYA_VERSION_STR=$(curl -s -u guest:guest_Api789 -X PROPFIND -H 'Depth: 1' ${XIAOYA_ALIST_HOST}/dav  | xq | jq -r '.["D:multistatus"]["D:response"][] | select(.["D:propstat"]["D:prop"]["D:displayname"] | contains("©")) | .["D:propstat"]["D:prop"]["D:displayname"]')
if [ -z "${XIAOYA_VERSION_STR}" ]; then
  echo -e "could not found current xiaoya version"
  exit 1
fi

XIAOYA_VERSION=${XIAOYA_VERSION_STR##* v.}

CONFIG_FILE_NAME=config-${XIAOYA_VERSION}.mp4
METADATA_FILE_NAME=all-${XIAOYA_VERSION}.mp4

echo "latest xiaoya version: ${XIAOYA_VERSION}"

fetch_config() {
  config_file=${TEMP_DIR}/${CONFIG_FILE_NAME}
  if [ -e "${config_file}" ];then
      if [ -e "${config_file}.aria2" ]; then
          echo "${config_file}" downloading...
        else
          echo "config already update to ${XIAOYA_VERSION}"
          return
      fi
  fi
  aria2c -o ${config_file} --enable-color=false --auto-file-renaming=false --allow-overwrite=true -c -x6 "${XIAOYA_ALIST_HOST}/d/元数据/config.mp4"
  rm -rf ${EMBY_CONFIG_DIR}/*
  pushd /
  echo "start decompress ${config_file}"
    # 7z x -bb0 -aoa -mmt=16 ${config_file} 2>/dev/null
    7z x -bb0 -aoa -mmt=16 ${config_file}
  popd

  echo "decompress ${config_file} finished"
  chmod -R 777 ${EMBY_CONFIG_DIR}
}

fetch_metadata() {
  config_file=${TEMP_DIR}/${METADATA_FILE_NAME}
  if [ -e "${config_file}" ];then
      if [ -e "${config_file}.aria2" ]; then
          echo "${config_file}" downloading...
        else
          echo "metadata already update to ${XIAOYA_VERSION}"
          return
      fi
  fi
  echo "start download ${config_file}"
  aria2c -o ${config_file} --enable-color=false --auto-file-renaming=false --allow-overwrite=true -c -x6 "${XIAOYA_ALIST_HOST}/d/元数据/all.mp4"
  rm -rf ${METADATA_DIR}/*
  pushd ${METADATA_DIR}
  echo "start decompress ${config_file}"
    7z x -bb0 -aoa -mmt=16 ${config_file}
  popd
  echo "decompress ${config_file} finished"
  chmod -R 777 ${METADATA_DIR}
}


fetch_config
fetch_metadata
