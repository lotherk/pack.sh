#!/bin/sh
# generator: d75d37d73db86e964132c83f1c9976b9acaa8ed361a8a34820aadb58df21de47  ./pack.sh
# date: Mon Mar 23 03:18:04 PM WET 2026
# build: lotherk @ Linux n95 6.12.74+deb13+1-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.12.74-2 (2026-03-08) x86_64 GNU/Linux
# payload_sha256: b9548e47bf2513c265e4fe8a44d2d63686b8af86cab3ae15e55e11e2a08895c9

PAYLOAD="jA0ECQMKbiBSbrMzfvn/0nEBdnuz9tln7Xtv27S5diwvNBAMn3jVWlgtZXgZqm9FMvGXTIewDmWog4eriYLHHlqqpLWvJz1VNFokIyorN0Wm5TFsVOP3Ii2xu+N/R0CAmaCCKXADysxgn6XG7dL3AoI6rH9bnSiecBcJo7GUJD4QmA=="

set -e

# Check for required commands
if ! command -v gpg >/dev/null 2>&1; then
    echo "Error: gpg is required to run this script" >&2
    exit 1
fi

if ! command -v base64 >/dev/null 2>&1; then
    echo "Error: base64 is required to run this script" >&2
    exit 1
fi

if ! command -v mktemp >/dev/null 2>&1; then
    echo "Error: mktemp is required to run this script" >&2
    exit 1
fi

# Check for password in environment variable
if [ -n "${PASSWORD:-}" ]; then
    :
else
    printf 'Enter password to decrypt and run the script: ' >&2
    stty -echo < /dev/tty
    read PASSWORD < /dev/tty
    stty echo < /dev/tty
    printf '
' >&2
fi

if ! command -v sha256sum >/dev/null 2>&1; then
    echo "Error: sha256sum is required to run this script" >&2
    exit 1
fi

# Verify payload integrity via checksum
if [ "$(echo "$PAYLOAD" | sha256sum | awk '{print $1}')" != "b9548e47bf2513c265e4fe8a44d2d63686b8af86cab3ae15e55e11e2a08895c9" ]; then
    echo "Error: Checksum mismatch! Payload may be corrupted." >&2
    exit 2
fi

# Decode the base64 data and decrypt with GPG
DECRYPTED=$(echo "$PAYLOAD" | base64 -d | gpg --batch --passphrase "$PASSWORD" --decrypt)

# Write to temp file and execute
TEMP_SCRIPT=$(mktemp)
trap 'rm -f "$TEMP_SCRIPT"' EXIT
echo "$DECRYPTED" > "$TEMP_SCRIPT"
chmod 0700 "$TEMP_SCRIPT"

clear
exec sh -ci "$TEMP_SCRIPT"
