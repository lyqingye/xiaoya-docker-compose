#!/usr/bin/env bash

REFRESH_TOKEN_FILE_PATH=/alist/mytoken.txt
TEMP_FOLDER_ID_FILE_PATH=/alist/temp_transfer_folder_id.txt

REFRESH_TOKEN=$(cat "${REFRESH_TOKEN_FILE_PATH}")
TEMP_FOLDER_ID=$(cat "${TEMP_FOLDER_ID_FILE_PATH}")

if [ -z "${REFRESH_TOKEN}" ]; then
    echo "env REFRESH_TOKEN not set"
fi

if [ -z "${TEMP_FOLDER_ID}" ]; then
    echo "env TEMP_FOLDER_ID not set"
fi

ACCESS_TOKEN=
RESOURCE_DRIVE_ID=
DEFAULT_DRIVE_ID=

get_access_token() {
    response=$(curl --connect-timeout 5 \
        -m 5 \
        -s \
        -H "Content-Type: application/json" \
        -d '{"grant_type":"refresh_token", "refresh_token":"'$REFRESH_TOKEN'"}' \
        https://api.aliyundrive.com/v2/account/token)
    access_token=$(echo "$response" | jq -r '.access_token')
    if [ -z "$access_token" ] || [ "$access_token" = "null" ]; then
        echo "get_access_token error: $(echo "$response" | jq -r '.message')"
        return 1
    fi

    ACCESS_TOKEN=${access_token}
    return 0
}

get_drive_id() {
    response=$(curl \
        --connect-timeout 5 \
        -m 5 \
        -s \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{}' \
        "https://user.aliyundrive.com/v2/user/get")
    default_drive_id=$(echo "$response" | jq -r '.default_drive_id')
    if [ -z "$default_drive_id" ] || [ "$default_drive_id" = "null" ]; then
        echo "empty default_drive_id error: $(echo "$response" | jq -r '.message')"
        return 1
    fi
    resource_drive_id=$(echo "$response" | jq -r '.resource_drive_id')
    if [ -z "$resource_drive_id" ] || [ "$resource_drive_id" = "null" ]; then
        echo "empty resource_drive_id error: $(echo "$response" | jq -r '.message')"
        return 1
    fi
    RESOURCE_DRIVE_ID=${resource_drive_id}
    DEFAULT_DRIVE_ID=${default_drive_id}
    return 0
}

# params1: folder_id
delete_files_in_folder() {
    folder_id=$1
    next_marker=""
    while true; do
        response=$(curl \
            --connect-timeout 5 \
            -m 5 \
            -s \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -X POST \
            -d "{\"drive_id\": \"$RESOURCE_DRIVE_ID\",\"parent_file_id\": \"$folder_id\", \"marker\": \"${next_marker}\" }" \
            "https://api.aliyundrive.com/adrive/v2/file/list")

        count=$(echo "$response" | jq -r '.items | length')
        next_marker=$(echo "$response" | jq -r '.next_marker')

        for ((i = 0; i < count; i++)); do
            file_name=$(echo "$response" | jq -r ".items[$i].name")
            file_id=$(echo "$response" | jq -r ".items[$i].file_id")
            file_type=$(echo "$response" | jq -r ".items[$i].type")
            drive_id=$(echo "$response" | jq -r ".items[$i].drive_id")
            case "$file_type" in
            "file")
                status=$(curl --connect-timeout 5 -m 5 -s \
                    -H "Authorization: Bearer $ACCESS_TOKEN" \
                    -H "Content-Type: application/json" \
                    -X POST \
                    -d '{
                        "requests": [
                            {
                            "body": {
                                "drive_id": "'"$drive_id"'",
                                "file_id": "'"$file_id"'"
                            },
                            "headers": {
                                "Content-Type": "application/json"
                            },
                            "id": "'"$file_id"'",
                            "method": "POST",
                            "url": "/file/delete"
                            }
                        ],
                        "resource": "file"
                        }' \
                    "https://api.aliyundrive.com/v3/batch" | jq -r '.responses[0].status')

                if [ "${status}" = "204" ]; then
                    echo "delete file: ${file_name} success!"
                else
                    echo "delete file: ${file_name} error. code: ${status}"
                fi

                ;;
            "folder")
                if ! delete_files_in_folder "${file_id}"; then
                    return 1
                fi
                ;;
            *)
                echo "unknown file type: ${file_name} ${file_type}"
                continue
                ;;
            esac
        done

        # end of page
        if [ -z "$next_marker" ] || [ "$next_marker" = "null" ]; then
            return 0
        fi
    done

}

echo "running aliyunpan cleaner..."

if get_access_token; then
    if get_drive_id; then
        delete_files_in_folder "${TEMP_FOLDER_ID}"
    else
        exit 1
    fi
else
    exit 1
fi
