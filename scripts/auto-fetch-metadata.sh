#!/usr/bin/env bash

ALIST_IMAGE=xiaoyaliu/alist
XIAOYA_ALIST_HOST=http://xiaoya-real.host

docker stop xiaoya-alist-updater

while true; do
    response=$(curl -s -o /dev/null -w "%{http_code}" ${XIAOYA_ALIST_HOST}/dav)
    if [ "$response" -eq 401 ]; then
        break
    else
        echo "wait xiaoya alist start finished..."
        sleep 2s
    fi
done

# update metadata

docker stop emby-server
bash /root/scripts/fetch-metadata.sh
docker start xiaoya-alist-updater
docker start emby-server

if [ "$1" = "true" ]; then
  supercronic /root/scripts/crontab
fi
