#!/bin/sh

###############################################################################
#                                                                             #
#  pack.sh - Encrypted Script Wrapper                                         #
#                                                                             #
###############################################################################

# =============================================================================
# DESCRIPTION
# =============================================================================
#
# pack.sh encrypts any executable script (bash, python, etc.) using GPG
# symmetric encryption and base64 encoding, producing a self-contained wrapper
# script for secure remote execution. The generated wrapper can be hosted on
# a web server and executed remotely via `curl | sh` with password protection.
#
# =============================================================================
# SPECS
# =============================================================================
#
# Input:         Any executable script file (bash, python, node.js, etc.)
# Output:        Self-contained POSIX sh wrapper script with embedded encrypted payload
# Encryption:    GPG symmetric encryption (--symmetric)
# Encoding:      base64 (line-wrapped disabled via -w 0)
# Integrity:     SHA256 checksum verification in generated wrapper
#
# =============================================================================
# PASSWORD SOURCES (in order of precedence)
# =============================================================================
#
# 1. PASSWORD environment variable (recommended for automation)
# 2. stdin (piped input, e.g., `echo 'pass' | ./pack.sh script.sh`)
# 3. Interactive terminal prompt (if stdin is a TTY)
#
# =============================================================================
# REQUIREMENTS
# =============================================================================
#
# For pack.sh (encryption):
#   - gpg        (GNU Privacy Guard)
#   - base64     (standard Unix utility)
#   - sha256sum  (for checksum generation)
#
# For generated wrapper (decryption):
#   - gpg        (GNU Privacy Guard)
#   - base64     (standard Unix utility)
#   - mktemp     (for temporary file creation)
#   - sha256sum  (for checksum verification)
#
# =============================================================================
# USAGE
# =============================================================================
#
#   ./pack.sh <script_file> > <output_file>
#
# Examples:
#
#   # Interactive password prompt:
#   ./pack.sh your-script.sh > encrypted.sh
#
#   # Automated with password via stdin:
#   echo 'yourpassword' | ./pack.sh your-script.sh > encrypted.sh
#
#   # Automated with PASSWORD environment variable:
#   PASSWORD=yourpassword ./pack.sh your-script.sh > encrypted.sh
#
#   # Remote execution of generated wrapper:
#   curl https://your-server.com/encrypted.sh | sh
#
#   # Automated remote execution with PASSWORD:
#   PASSWORD=yourpassword sh -c "$(curl https://your-server.com/encrypted.sh)"
#
# =============================================================================
# AUTHORS
# =============================================================================
#
# Konrad 'lotherk' Lother <konrad@hiddenbox.org>
# In proud cooperation with Big Pickle from opencode <3
#
# =============================================================================
# LICENSE
# =============================================================================
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
# =============================================================================
# CHANGELOG
# =============================================================================
#
# v1.1.0 - Add PASSWORD environment variable support for automated encryption
# v1.0.0 - Initial release with encryption, base64 encoding, and checksum verification
#
# =============================================================================
# VERSION
# =============================================================================

VERSION="1.1.0"

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
            echo "Password (in order of precedence):"
            echo "  1. PASSWORD environment variable"
            echo "  2. stdin (piped input)"
            echo "  3. Interactive terminal prompt"
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

# Check for required commands (gpg for encryption, base64 for encoding, sha256sum for checksum)
if ! command -v gpg >/dev/null 2>&1; then
    echo "Error: gpg is required but not installed" >&2
    exit 1
fi

if ! command -v base64 >/dev/null 2>&1; then
    echo "Error: base64 is required but not installed" >&2
    exit 1
fi

if ! command -v sha256sum >/dev/null 2>&1; then
    echo "Error: sha256sum is required but not installed" >&2
    exit 1
fi

# Get password from environment variable, stdin, or interactive prompt
if [ -n "${PASSWORD:-}" ]; then
    PASSWORD1="$PASSWORD"
    PASSWORD2="$PASSWORD"
elif [ -t 0 ]; then
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
