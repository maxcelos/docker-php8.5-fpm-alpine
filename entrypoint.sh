#!/bin/sh
# Update
HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1000}

echo "Configuring users and groups with HOST_UID=${HOST_UID} and HOST_GID=${HOST_GID}"

# --- Handle www-data if it exists ---
if id "www-data" >/dev/null 2>&1; then
    echo "User www-data found. Attempting to change UID/GID to ${HOST_UID}:${HOST_GID}"

    # Try to modify www-data's primary group to HOST_GID
    # Check if the GID 1000 is already in use by a different group than www-data's current primary group
    current_www_data_gid=$(id -g www-data)
    current_www_data_group_name=$(getent group "$current_www_data_gid" | cut -d: -f1)

    # If the target GID is 1000, and it's already used by another group, we might need to be careful.
    # For simplicity and robustness, let's try to set www-data's group directly.
    # If the target GID is already taken by *another* group, groupmod might fail.
    # A safer approach is to assign www-data to a new group if the HOST_GID is problematic.

    # Option 1: Try to modify www-data's existing group or assign it to a new one
    # This part is tricky if HOST_GID is already taken by a different group.
    # A common approach for www-data in Alpine is to make it belong to a group with GID 1000.

    # Check if a group with HOST_GID already exists
    if getent group "${HOST_GID}" >/dev/null 2>&1; then
        echo "Group with GID ${HOST_GID} already exists: $(getent group "${HOST_GID}" | cut -d: -f1). Assigning www-data to this group."
        group_name_for_www_data=$(getent group "${HOST_GID}" | cut -d: -f1)
        usermod -g "${group_name_for_www_data}" www-data
    else
        echo "Creating group 'www-data' with GID ${HOST_GID} for www-data user."
        addgroup -g "${HOST_GID}" www-data # Create a new group named 'www-data' with the desired GID
        usermod -g www-data www-data # Assign www-data to this new group
    fi

    usermod -u "${HOST_UID}" www-data # Change www-data's UID
    echo "www-data UID/GID changed to $(id -u www-data):$(id -g www-data)"

# --- Handle appuser if www-data doesn't exist or is not suitable ---
else
    echo "www-data user not found or not primary. Configuring 'appuser' for application."

    # First, ensure appuser and appgroup are cleaned up if they exist from a prior run
    if id "appuser" >/dev/null 2>&1; then
        echo "User appuser found. Removing to reconfigure."
        deluser appuser || true
    fi
    if getent group appgroup >/dev/null 2>&1; then
        echo "Group appgroup found. Removing to reconfigure."
        delgroup appgroup || true
    fi

    # Try to create appgroup with HOST_GID. If GID is in use, create without specific GID.
    APP_GROUP_NAME="appgroup"
    if getent group "${HOST_GID}" >/dev/null 2>&1; then
        echo "GID ${HOST_GID} is already in use by group: $(getent group "${HOST_GID}" | cut -d: -f1). Creating ${APP_GROUP_NAME} without specific GID."
        addgroup "${APP_GROUP_NAME}" # Let addgroup assign a free GID
    else
        echo "Creating group '${APP_GROUP_NAME}' with GID ${HOST_GID}."
        addgroup -g "${HOST_GID}" "${APP_GROUP_NAME}"
    fi

    # Create appuser with HOST_UID and assign to appgroup
    echo "Creating appuser with UID ${HOST_UID} and assigning to group ${APP_GROUP_NAME}."
    adduser -u "${HOST_UID}" -G "${APP_GROUP_NAME}" -s /bin/sh -D appuser
fi

# --- Set ownerships (common to both scenarios) ---
# Ensure appuser/www-data's actual UID/GID are used for chown
# Determine the effective UID/GID for ownership based on which user was configured
EFFECTIVE_OWNER_UID=$(id -u appuser 2>/dev/null || id -u www-data 2>/dev/null)
EFFECTIVE_OWNER_GID=$(id -g appuser 2>/dev/null || id -g www-data 2>/dev/null)

if [ -z "$EFFECTIVE_OWNER_UID" ] || [ -z "$EFFECTIVE_OWNER_GID" ]; then
    echo "Warning: Could not determine effective owner UID/GID. Falling back to HOST_UID:HOST_GID."
    EFFECTIVE_OWNER_UID="${HOST_UID}"
    EFFECTIVE_OWNER_GID="${HOST_GID}"
fi

echo "Setting ownership for directories to ${EFFECTIVE_OWNER_UID}:${EFFECTIVE_OWNER_GID}"
chown -R "${EFFECTIVE_OWNER_UID}":"${EFFECTIVE_OWNER_GID}" /var/www/vhost/lscore/storage || true
chown -R "${EFFECTIVE_OWNER_UID}":"${EFFECTIVE_OWNER_GID}" /var/www/vhost/lscore/bootstrap/cache || true
chown -R "${EFFECTIVE_OWNER_UID}":"${EFFECTIVE_OWNER_GID}" /composer || true
chown -R "${EFFECTIVE_OWNER_UID}":"${EFFECTIVE_OWNER_GID}" /.npm || true

exec "$@"