# pack.sh - Agents Documentation

## Project Overview

pack.sh encrypts any executable script (bash, python, node.js, etc.) using GPG symmetric encryption and base64 encoding, producing a self-contained wrapper script for secure remote execution.

## Project Structure

```
pack.sh/           - Main project directory
  pack.sh          - Encryption tool (POSIX /bin/sh)
  README.md         - Project documentation
  AGENTS.md         - This file (for agent context)
```

## Technical Specifications

### Input
- Any executable script file with shebang (bash, python, node.js, etc.)

### Output
- Self-contained POSIX sh wrapper script with embedded encrypted payload

### Encryption
- GPG symmetric encryption (`--symmetric`)
- Encoding: base64 with line wrapping disabled (`-w 0`)
- Integrity: SHA256 checksum verification in generated wrapper
- Payload stored in `PAYLOAD` variable in wrapper script

### Password Sources (in order of precedence)
1. `PASSWORD` environment variable (recommended for automation)
2. stdin (piped input)
3. Interactive terminal prompt (if stdin is a TTY)

### Requirements

**For pack.sh (encryption):**
- gpg
- base64
- sha256sum

**For generated wrapper (decryption):**
- gpg
- base64
- mktemp
- sha256sum

## Usage

```bash
# Interactive password prompt
./pack.sh your-script.sh > encrypted.sh

# Automated with password via stdin
echo 'yourpassword' | ./pack.sh your-script.sh > encrypted.sh

# Automated with PASSWORD environment variable
PASSWORD=yourpassword ./pack.sh your-script.sh > encrypted.sh

# Remote execution
curl https://your-server.com/encrypted.sh | sh
PASSWORD=yourpassword sh -c "$(curl https://your-server.com/encrypted.sh)"
```

## Version

Current version: 1.2.0

## Changelog

- v1.2.0 - Use PAYLOAD variable for base64 data and exec for execution
- v1.1.0 - Add PASSWORD environment variable support for automated encryption
- v1.0.0 - Initial release with encryption, base64 encoding, and checksum verification

## Development Guidelines

- Maintain POSIX compatibility (use `/bin/sh`, not bash-specific features)
- Generated wrapper must also be POSIX compatible
- Use `set -e` for error handling
- Always verify payload integrity with SHA256 checksum
- Clean up temporary files with trap on EXIT
- Password handling: silent input with stty -echo when TTY available
- MIT License - include in header comments

## Author

Konrad 'lotherk' Lother <konrad@hiddenbox.org>
In proud cooperation with Big Pickle from opencode
