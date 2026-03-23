#!/bin/sh
set -e

SCRIPT="test/test_script.sh"
ENCRYPTED="test/encrypted.sh"

echo "Encrypting $SCRIPT..."
echo "test" | ./pack.sh "$SCRIPT" > "$ENCRYPTED"

echo "Decrypting and running..."
PASSWORD=test sh "$ENCRYPTED"