#!/bin/bash
# Eciv13 Unified Server Management Script

# Read configuration from paths.txt
MDIR=$(sed -n '2p' paths.txt | sed 's/mdir://' | tr -d '\r')
CDIR=$(sed -n '3p' paths.txt | sed 's/cdir://' | tr -d '\r')
PORT=$(sed -n '4p' paths.txt | sed 's/port://' | tr -d '\r')

GIT_DIR="${MDIR}civ13-git"
ACTIVE_DIR="${MDIR}${CDIR}"

case "$1" in
    update|launch|swap)
        echo "Updating repository from git..."
        cd "$GIT_DIR" || exit 1
        git pull
        git reset --hard origin/master

        echo "Rebuilding binaries..."
        DreamMaker civ13.dme

        echo "Copying configuration files using copiedconfigpaths.txt..."
        CONFIG_LIST="${ACTIVE_DIR}/scripts/copiedconfigpaths.txt"
        if [ -f "$CONFIG_LIST" ]; then
            while IFS= read -r path; do
                [ -z "$path" ] && continue
                path=$(echo "$path" | tr -d '\r')
                if [ -f "${GIT_DIR}/${path}" ]; then
                    cp -f "${GIT_DIR}/${path}" "${ACTIVE_DIR}/${path}"
                    echo "Copied config: $path"
                fi
            done < "$CONFIG_LIST"
        fi

        echo "Copying configuration folders using copiedfolderpaths.txt..."
        FOLDER_LIST="${ACTIVE_DIR}/scripts/copiedfolderpaths.txt"
        if [ -f "$FOLDER_LIST" ]; then
            while IFS= read -r path; do
                [ -z "$path" ] && continue
                path=$(echo "$path" | tr -d '\r')
                npath="${ACTIVE_DIR}/${path}"
                if [ -d "${GIT_DIR}/${path}" ]; then
                    if [ -d "$npath" ]; then
                        rm -rf "$npath"
                    fi
                    cp -r "${GIT_DIR}/${path}" "$npath"
                    echo "Copied folder: $path"
                fi
            done < "$FOLDER_LIST"
        fi

        echo "Copying compiled binaries (.dmb & .rsc)..."
        cp -f "${GIT_DIR}/civ13.dmb" "${ACTIVE_DIR}/civ13.dmb"
        cp -f "${GIT_DIR}/civ13.rsc" "${ACTIVE_DIR}/civ13.rsc"

        if [ "$1" = "swap" ] || [ "$1" = "launch" ]; then
            echo "Stopping existing server instances on port $PORT..."
            pkill -f "civ13.dmb.*$PORT"

            echo "Starting DreamDaemon on port $PORT..."
            nohup DreamDaemon "${ACTIVE_DIR}/civ13.dmb" "$PORT" -trusted -webclient -logself > /dev/null 2>&1 &
            echo "Eciv13 successfully started/swapped on port $PORT!"
        fi
        ;;
    kill)
        echo "Killing Eciv13 instances on port $PORT..."
        pkill -f "civ13.dmb.*$PORT"
        ;;
    *)
        echo "Usage: ./manage.sh {update|launch|swap|kill}"
        exit 1
        ;;
esac