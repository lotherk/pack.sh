#!/bin/sh

# pack.sh: Encrypt and wrap executable scripts for secure remote execution
# Usage: ./pack.sh <script_file> > <output_file>
#
# MIT License
#
# Copyright (c) 2026 Konrad Lother
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Changelog:
# v1.0.0 - Initial release with encryption, base64 encoding, and checksum verification
#
# Version
VERSION="1.0.0"

set -e

# Parse arguments
while getopts "h" opt; do
    case $opt in
        h)
            echo "pack.sh v$VERSION - Encrypt and wrap executable scripts for secure remote execution"
            echo ""
            echo "Usage: $0 <script_file> > <output_file>"
            echo ""
            echo "This script encrypts the given script file using GPG symmetric encryption,"
            echo "base64-encodes the result, and generates a self-contained wrapper script."
            echo "The wrapper can be executed remotely (e.g., via curl | sh) with password protection."
            echo ""
            echo "Options:"
            echo "  -h    Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 myscript.sh > encrypted.sh"
            echo "  echo 'password' | $0 myscript.sh > encrypted.sh"
            echo "  PASSWORD=mypass $0 myscript.sh > encrypted.sh"
            exit 0
            ;;
        *)
            echo "Usage: $0 <script_file>" >&2
            exit 1
            ;;
    esac
done

if [ $# -ne 1 ]; then
    echo "Usage: $0 <script_file>" >&2
    exit 1
fi

SCRIPT_FILE="$1"

# Validate input file
if [ ! -f "$SCRIPT_FILE" ]; then
    echo "Error: '$SCRIPT_FILE' is not a regular file" >&2
    exit 1
fi

if [ ! -r "$SCRIPT_FILE" ]; then
    echo "Error: '$SCRIPT_FILE' is not readable" >&2
    exit 1
fi

# Check for required commands (gpg for encryption, base64 for encoding)
if ! command -v gpg >/dev/null 2>&1; then
    echo "Error: gpg is required but not installed" >&2
    exit 1
fi

if ! command -v base64 >/dev/null 2>&1; then
    echo "Error: base64 is required but not installed" >&2
    exit 1
fi

# Prompt for password
if [ -t 0 ]; then
    echo "Enter password for encryption:" >&2
    stty -echo
    read PASSWORD1
    stty echo
    echo "" >&2
    echo "Confirm password:" >&2
    stty -echo
    read PASSWORD2
    stty echo
    echo "" >&2
else
    read PASSWORD1
    PASSWORD2="$PASSWORD1"
fi

if [ "$PASSWORD1" != "$PASSWORD2" ]; then
    echo "Error: Passwords do not match" >&2
    exit 1
fi

# Encrypt the script and base64-encode the result
ENCRYPTED_DATA=$(gpg --batch --passphrase "$PASSWORD1" --symmetric --output - "$SCRIPT_FILE" | base64 -w 0)

# Compute checksum for payload integrity verification
PAYLOAD_CHECKSUM=$(echo "$ENCRYPTED_DATA" | sha256sum | awk '{print $1}')
# Generate wrapper script
OUTPUT=$(
cat <<EOF
#!/bin/sh
# generator: $(sha256sum "${0}")
# date: $(date)
# build: $(whoami) @ $(uname -a)
# payload_sha256: $PAYLOAD_CHECKSUM

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
if [ -n "\${PASSWORD:-}" ]; then
    :
else
    printf 'Enter password to decrypt and run the script: ' >&2
    stty -echo < /dev/tty
    read PASSWORD < /dev/tty
    stty echo < /dev/tty
    printf '\n' >&2
fi

if ! command -v sha256sum >/dev/null 2>&1; then
    echo "Error: sha256sum is required to run this script" >&2
    exit 1
fi

# Verify payload integrity via checksum
if [ "\$(echo "$ENCRYPTED_DATA" | sha256sum | awk '{print \$1}')" != "$PAYLOAD_CHECKSUM" ]; then
    echo "Error: Checksum mismatch! Payload may be corrupted." >&2
    exit 2
fi

# Decode the base64 data and decrypt with GPG
DECRYPTED=\$(echo "$ENCRYPTED_DATA" | base64 -d | gpg --batch --passphrase "\$PASSWORD" --decrypt)


# Write to temp file and execute
TEMP_SCRIPT=\$(mktemp)
trap 'rm -f "\$TEMP_SCRIPT"' EXIT
echo "\$DECRYPTED" > "\$TEMP_SCRIPT"
chmod 0700 "\$TEMP_SCRIPT"

"\$TEMP_SCRIPT"

EOF
)

echo "$OUTPUT"