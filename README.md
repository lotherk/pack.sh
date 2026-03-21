# pack.sh - Encrypted Script Wrapper

A POSIX-compatible bash script that encrypts any executable script (bash, python, etc.) using GPG and base64 encoding, producing a self-contained wrapper script for secure remote execution.

## Features

- Encrypts scripts with GPG symmetric encryption
- Supports any script with a shebang (bash, python, node.js, etc.)
- Generates a wrapper script that can be hosted on a web server
- Allows remote execution via `curl | bash` with password protection
- Automatic shebang detection and execution with appropriate interpreter

## Requirements

- `gpg` (GNU Privacy Guard)
- `base64` (standard Unix utility)
- Bash (for the wrapper script)

## Installation

Clone or download `pack.sh` and make it executable:

```bash
chmod +x pack.sh
```

## Usage

### Creating an Encrypted Script Wrapper

```bash
./pack.sh your-script.sh > encrypted-wrapper.sh
```

Or for Python scripts:

```bash
./pack.sh your-script.py > encrypted-wrapper.sh
```

You'll be prompted to enter and confirm a password for encryption.

### Hosting and Remote Execution

1. Upload `encrypted-wrapper.sh` to your web server
2. Execute remotely:

```bash
curl https://your-server.com/encrypted-wrapper.sh | bash
```

3. Enter the password when prompted to decrypt and run the script

## How It Works

1. `pack.sh` validates the input script and encrypts it using GPG with your password
2. The encrypted data is base64-encoded and embedded in a bash wrapper script
3. The wrapper script, when executed, prompts for the password, decrypts the payload, detects the original script's shebang, and runs it with the appropriate interpreter

## Security Notes

- Passwords are read silently (no echo)
- Encrypted data is handled in memory and temporary files are cleaned up
- No sensitive information is exposed in error messages
- Use strong passwords for encryption

## Examples

### Bash Script
```bash
echo '#!/bin/bash
echo "Hello from encrypted bash script!"
' > hello.sh
chmod +x hello.sh
./pack.sh hello.sh > hello-encrypted.sh
```

### Python Script
```bash
echo '#!/usr/bin/env python3
print("Hello from encrypted python script!")
' > hello.py
chmod +x hello.py
./pack.sh hello.py > hello-encrypted.sh
```

### Remote Execution
```bash
# Host hello-encrypted.sh on your server, then:
curl https://example.com/hello-encrypted.sh | bash
# Enter password when prompted
```

## Compatibility

- POSIX-compliant bash script
- Works on Linux, macOS, and other Unix-like systems
- Supports various interpreters based on shebang detection

## License

This project is released under the MIT License.